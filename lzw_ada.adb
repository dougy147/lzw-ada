with Lzw;
with Args; use Args;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

function Lzw_Ada return Integer is
    Result_Parse_Args : Integer;
begin
    Result_Parse_Args := Args.Parse_Args;

    if Result_Parse_Args >= 0 then -- user asked Usage or args parsing error
        return Result_Parse_Args;
    end if;

    if Args.Mode = Compress then
        Lzw.Encode_Lzw (Input_File_Path    => To_String(Input_File_Path),
                        Output_File_Path   => To_String(Output_File_Path),
                        Max_Bits_Pack_Size => Max_Bits_Pack_Size);

    elsif Args.Mode = Decompress then
        Lzw.Decode_Lzw (Input_File_Path    => To_String(Input_File_Path),
                        Output_File_Path   => To_String(Output_File_Path),
                        Max_Bits_Pack_Size => Max_Bits_Pack_Size);
    end if;

    return 0;
end Lzw_Ada;
