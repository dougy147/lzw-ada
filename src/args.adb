package body Args is

    procedure Usage (Exit_Code: Integer; Error_Message: String := "") is
    begin

        Put_Line("USAGE: " & Command_Name & " <FLAGS> <INPUT_FILE> [OPTS]");
        Put_Line("FLAGS:");
        Put_Line("    c|compress");
        Put_Line("    d|decompress");
        Put_Line("OPTS:");
        Put_Line("    -o|--output <FILE>  : default=INPUT_FILE.lzw");
        Put_Line("    -b|--max-bits <INT> : limit for bits-packing size");

        if Exit_Code /= 0 then
            raise PROGRAM_ERROR with "[!] " & Error_Message;
        end if;
    end Usage;

    function Parse_Args return Integer is
        Pass_Arg : Boolean := False;
    begin
        for I in 1..Argument_Count loop

            if not Pass_Arg then

                if Argument(I) = "--help" or Argument(I) = "help" or Argument(I) = "-h" then
                    Usage(Exit_Code => 0);
                    return -1;

                elsif Argument(I) = "compress"   or Argument(I) = "c" then
                    Mode := Compress;

                elsif Argument(I) = "decompress" or Argument(I) = "d" then
                    Mode := Decompress;

                elsif Argument(I) = "-o" or Argument(I) = "--output" then
                    if I + 1 > Argument_Count then
                        Usage(1, "`" & Argument(I) & "` expects an output file path");
                    end if;
                    Output_File_Path := To_Unbounded_String(Argument(I+1));
                    Pass_Arg := True;
       
                elsif Argument(I) = "-b" or Argument(I) = "--max-bits" then
                    if I + 1 > Argument_Count then
                        Usage(1, "`" & Argument(I) & "` expects an integer");
                    end if;
                    Max_Bits_Pack_Size := Integer'Value(Argument(I+1)); -- TODO ensure conversion is possible
                    if Max_Bits_Pack_Size > 62 then
                        Usage(1, "Compressing the universe!? We limited bits-packing to 62, sorry.");
                    end if;
                    Pass_Arg := True;

                else
                    -- TODO: improve this sketchy way of getting input file
                    Input_File_Path := To_Unbounded_String(Argument(I));
                    if not Exists(To_String(Input_File_Path)) then
                        Usage(1, "`" & Argument(I) & "` is not a valid input file");
                    end if;

                end if;

            else

                Pass_Arg := False;

            end if;
        end loop;

        if Input_File_Path = To_Unbounded_String("") then
            Usage(1, "Input file is required");
        end if;

        if Mode = None then
            Usage(1,"Mode must be one of `compress`, `decompress`");
        end if;

        if Output_File_Path = To_Unbounded_String("") then
            if Mode = Compress then
                Output_File_Path := Input_File_Path & To_Unbounded_String(".lzw");
            elsif Mode = DeCompress then
                Output_File_Path := Input_File_Path & To_Unbounded_String(".decoded");
            end if;
        end if;

        return 0;
    end;

end Args;
