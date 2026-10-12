with Lzw;

procedure Main is
begin
    Lzw.Encode_Lzw (Input_File_Path  => "README.md", 
                    Output_File_Path => "readme.lzw");

    Lzw.Decode_Lzw (Input_File_Path  => "readme.lzw", 
                    Output_File_Path => "README.md.decoded");
end Main;
