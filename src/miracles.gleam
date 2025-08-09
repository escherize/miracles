import glance
import glance_printer
import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/option
import gleam/string
import simplifile

const input_file = "src/input_code.gleam"

const output_file = "src/output_code.gleam"

// Type alias for macro functions
pub type MacroFunction =
  fn(glance.Definition(glance.CustomType)) ->
    List(glance.Definition(glance.Function))

// Configuration: mapping from annotation names to macro functions
fn get_macro_registry() -> Dict(String, MacroFunction) {
  dict.new()
  |> dict.insert("make_printer", make_printer_macro)
}

pub fn main() {
  let assert Ok(code) = simplifile.read(input_file)
  let assert Ok(parsed) = glance.module(code)

  let macro_registry = get_macro_registry()
  let transformed_ast = process_module_with_macros(parsed, code, macro_registry)
  echo transformed_ast as "transformed ast"
  let output = glance_printer.print(transformed_ast)

  let assert Ok(_) = simplifile.write(output_file, output)
  io.println("Generated output_code.gleam with macro transformations")
}

// Process the module by finding annotations and applying corresponding macros
fn process_module_with_macros(
  module: glance.Module,
  source_code: String,
  macro_registry: Dict(String, MacroFunction),
) -> glance.Module {
  let glance.Module(
    imports: imports,
    custom_types: custom_types,
    type_aliases: type_aliases,
    constants: constants,
    functions: functions,
  ) = module

  // Scan for annotations and generate new functions
  let new_functions =
    list.fold(custom_types, [], fn(acc_functions, type_def) {
      case
        find_annotations_for_definition(type_def, source_code, macro_registry)
      {
        [] -> acc_functions
        annotation_functions -> list.append(annotation_functions, acc_functions)
      }
    })

  glance.Module(
    imports: add_required_imports(imports, new_functions),
    custom_types: custom_types,
    type_aliases: type_aliases,
    constants: constants,
    functions: list.append(functions, new_functions),
  )
}

// Find annotations in comments before a definition and apply corresponding macros
fn find_annotations_for_definition(
  type_def: glance.Definition(glance.CustomType),
  source_code: String,
  macro_registry: Dict(String, MacroFunction),
) -> List(glance.Definition(glance.Function)) {
  let glance.Definition(_, custom_type) = type_def

  // Look for comments with @annotations before this type definition
  case find_annotation_in_source(custom_type.name, source_code) {
    option.Some(annotation_name) ->
      case dict.get(macro_registry, annotation_name) {
        Ok(macro_function) -> macro_function(type_def)
        Error(_) -> []
      }
    option.None -> []
  }
}

// Scan source code for @annotation comments before a type definition
fn find_annotation_in_source(
  type_name: String,
  source_code: String,
) -> option.Option(String) {
  // Simple approach: just look for the pattern // @annotation followed by type
  case
    string.contains(source_code, "// @make_printer")
    && string.contains(source_code, "pub type " <> type_name)
  {
    True -> option.Some("make_printer")
    False -> option.None
  }
}

// Add imports that might be required by generated functions
fn add_required_imports(
  current_imports: List(glance.Definition(glance.Import)),
  new_functions: List(glance.Definition(glance.Function)),
) -> List(glance.Definition(glance.Import)) {
  // For now, just add gleam/io if we have any new functions
  case new_functions {
    [] -> current_imports
    _ -> {
      let io_import =
        glance.Definition(
          [],
          glance.Import(
            module: "gleam/io",
            alias: option.None,
            unqualified_values: [],
            unqualified_types: [],
          ),
        )
      [io_import, ..current_imports]
    }
  }
}

// Macro function: generates a printer function for a custom type (AST-based)
fn make_printer_macro(
  type_def: glance.Definition(glance.CustomType),
) -> List(glance.Definition(glance.Function)) {
  let glance.Definition(_, custom_type) = type_def

  let function_name = "print_" <> string.lowercase(custom_type.name)
  let parameter_name = string.lowercase(custom_type.name)

  // Build the case expression with clauses for each variant
  let case_clauses =
    list.map(custom_type.variants, fn(variant) {
      glance.Clause(
        patterns: [
          [
            glance.PatternConstructor(
              constructor: variant.name,
              arguments: [],
              module: option.None,
              with_spread: False,
            ),
          ],
        ],
        guard: option.None,
        body: glance.Call(
          function: glance.FieldAccess(
            label: "println",
            container: glance.Variable("io"),
          ),
          arguments: [glance.UnlabelledField(glance.String(variant.name))],
        ),
      )
    })

  let case_expression =
    glance.Case(
      subjects: [glance.Variable(parameter_name)],
      clauses: case_clauses,
    )

  let printer_function =
    glance.Function(
      location: glance.Span(0, 0),
      name: function_name,
      publicity: glance.Public,
      parameters: [
        glance.FunctionParameter(
          label: option.None,
          name: glance.Named(parameter_name),
          type_: option.Some(glance.NamedType(
            name: custom_type.name,
            parameters: [],
            module: option.None,
          )),
        ),
      ],
      return: option.None,
      body: [glance.Expression(case_expression)],
    )

  [glance.Definition([], printer_function)]
}
