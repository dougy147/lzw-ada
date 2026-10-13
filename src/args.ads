with Ada.Command_Line; use Ada.Command_Line;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Directories; use Ada.Directories;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Args is

    type Process_Mode is (None, Compress, Decompress);

    -- Initialize default values
    Input_File_Path  : Unbounded_String := To_Unbounded_String("");
    Output_File_Path : Unbounded_String := To_Unbounded_String("");
    Mode : Process_Mode := None;

    procedure Usage (Exit_Code: Integer; Error_Message: String := "");
    function Parse_Args return Integer;

end Args;
