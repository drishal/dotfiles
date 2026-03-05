# Test Nix file for treesitter syntax highlighting
# This should show different colors for:
# - Keywords (let, in, with, inherit, rec)
# - Strings (double quotes)
# - Comments (like this)
# - Variables (x, y, pkgs)
# - Attributes (a, b)
# - Functions (f: x: ...)
# - Numbers (42, 3.14)

let
  # Define some variables
  x = 42;
  y = "hello world";

  # A function
  add = a: b: a + b;

  # Attribute set
  attrs = {
    a = 1;
    b = 2;
    c = add a b;
  };

  # With expression
  withAttrs = with attrs; a + b + c;

  # Inherit
  inherit (attrs) a b;

  # Recursive set
  recSet = rec {
    foo = "bar";
    baz = foo + "qux";
  };

in
{
  result = add x 10;
  message = y;
  computed = withAttrs;
  inherited = a + b;
  recursive = recSet.baz;
}
