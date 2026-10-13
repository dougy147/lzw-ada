with Lzw;
with Args; use Args;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

function Lzw_Ada return Integer is
begin
    if Args.Parse_Args < 0 then -- user asked Usage
        return 0;
    end if;

    if Args.Mode = Compress then
        Lzw.Encode_Lzw (To_String(Input_File_Path), To_String(Output_File_Path));
    elsif Args.Mode = Decompress then
        Lzw.Decode_Lzw (To_String(Input_File_Path), To_String(Output_File_Path));
    end if;

    return 0;
end Lzw_Ada;
