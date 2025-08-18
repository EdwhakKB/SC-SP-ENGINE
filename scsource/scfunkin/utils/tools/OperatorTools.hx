package scfunkin.utils.tools;

/**
 * Class meant to hold operator tools...?
 */
class OperatorTools
{
  public static var defaultComparisons:Map<String, (Float->Float->Float)->Bool> = [
    "=" => (a, b, c) -> return a == b,
    "<" => (a, b, c) -> return a < b,
    "<=" => (a, b, c) -> return a <= b,
    ">=" => (a, b, c) -> return a >= b,
    ">" => (a, b, c) -> return a > b,
    "==" => (a, b, c) -> return a == b == c,
    "< && <" => (a, b, c) -> return a < b && a < c,
    "> && >" => (a, b, c) -> return a > b && a > c,
    "< && >" => (a, b, c) -> return a < b && a > c,
    "> && <" => (a, b, c) -> return a > b && a < c,
    ">= && <" => (a, b, c) -> return a >= b && a < c,
    ">= && <=" => (a, b, c) -> return a >= b && a <= c,
    "<= && >" => (a, b, c) -> return a <= b && a > c,
    "<= && >=" => (a, b, c) -> a <= b && a >= c,
  ];
}
