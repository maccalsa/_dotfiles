#!/bin/bash
LANG="$1"
func_name=$(zenity --entry --title="${LANG^} Unit Test" --text="Function to test:")

case "$LANG" in
  python)
    snippet="import unittest\n\nclass TestMyFunc(unittest.TestCase):\n    def test_${func_name}(self):\n        self.assertTrue(True)"
    ;;
  java|kotlin)
    snippet="@Test\npublic void ${func_name}Test() {\n    assertTrue(true);\n}"
    ;;
  typescript)
    snippet="test('${func_name}', () => {\n    expect(true).toBeTruthy();\n});"
    ;;
  go)
    snippet="func Test${func_name}(t *testing.T) {\n    if true != true {\n        t.Errorf(\"Expected true\")\n    }\n}"
    ;;
  *)
    zenity --error --text="Unsupported language"; exit 1 ;;
esac

echo -e "$snippet"
