package body LZW is

    function Encoded_Key_Hash (Key: in Encoded_Key) return Hash_Type is
        -- TODO: How to hash tuples of two integers ""efficiently"" ??
        -- 0m4.915s on ./benchmark
        -- inspired by https://github.com/felixr/janet/commit/c1e1fd111e6844f7698f582eab8408a2fa0ecdb2
        H : Unsigned_32 := 5381;
    begin
        H := (H * 32) + H + Unsigned_32(Key.Prefix_Index);
        H := H xor + Unsigned_32(Key.Prefix_Index) + 2654435769 + (H * 64) + (H / 4);
        H := (H * 32) + H + Unsigned_32(abs Key.Suffix_Code);
        H := H xor + Unsigned_32(abs Key.Suffix_Code) + 2654435769 + (H * 64) + (H / 4);
        return Hash_Type(H mod 2147483648);
    end Encoded_Key_Hash;
    
    function Encoded_Key_Equivalence (Key_A, Key_B: in Encoded_Key) return Boolean is
    begin
        return Key_A.Prefix_Index = Key_B.Prefix_Index and Key_A.Suffix_Code = Key_B.Suffix_Code;
    end Encoded_Key_Equivalence;

    function Integer_Hash (Key: Integer) return Hash_Type is
    begin
        return Hash_Type(Key);
    end Integer_Hash;

    procedure Initialize_Encoding_Dictionnary (D: out Encoding_Hashed_Maps.Map) is
        Current_Key: Encoded_Key;
    begin
        for I in 0..255 loop
            Current_Key.Prefix_Index := I;
            Current_Key.Suffix_Code  := -1;
            D.Include(Current_Key, Integer(I));
        end loop;
    end;
    
    procedure Initialize_Decoding_Dictionnary (D: out Decoding_Hashed_Maps.Map) is
        Current_String:  Unbounded_String;
    begin
        for I in 0..255 loop
            Current_String := To_Unbounded_String("") & Character'Val(I);
            D.Include(Integer(I),Current_String);
        end loop;
    end;
    
    procedure LZW_Compress (Input_File_Path: String; Output_File_Path: String; Max_Bits_Pack_Size: Integer) is
        -- Read input file bufferized (~some small perf increase)
        Input_File: Stream_IO.File_Type;
        Data: Stream_Element_Array (1 .. 1024 * 1024); -- 1Mb chunks
        Last: Stream_Element_Offset;

        use Character_IO;
        Output_File: Character_IO.File_Type;

        Dictionnary: Encoding_Hashed_Maps.Map;
        Dictionnary_Length: Integer;
        Cursor: Encoding_Hashed_Maps.Cursor; -- for pointers instead of multiple pass in hash

        C: Integer; -- current byte read from input file
        Current_Code : Integer := 0;
        Current_Key : Encoded_Key;
 
        use Encoding_Hashed_Maps;
        First_Char: Stream_Element_Array (1 .. 1);

        Bits_Pack_Size: Integer := 9;
        Remaining_Bits_To_Pack_For_Current_Index: Integer;

        -- NOTE: Remember we process Input_File chunks byte by byte.
        -- Hence this variable name and its value of 8. <|:^)
        Byte_Free_Bits : Integer := 8;

        Byte_Value           : Integer := 0;
        Byte_Value_To_Append : Integer;

        Index      : Integer;
        Last_Index : Integer;

        Bit_Shift_Size : Integer; -- for readability

    begin

        Dictionnary.Reserve_Capacity(2 ** Max_Bits_Pack_Size);

        Initialize_Encoding_Dictionnary(Dictionnary);
        Dictionnary_Length := Integer(Dictionnary.Length);

        Open (File => Input_File, 
              Mode => In_File, 
              Name => Input_File_Path);

        Create(File => Output_File, 
               Mode => Out_File,
               Name => Output_File_Path);

        -- read first char
        Read(Input_File, First_Char, Last);
        C := Integer(First_Char(1));
        --Put(C'Image);
        Current_Code := Dictionnary((Prefix_Index => C, Suffix_Code => -1));

        while not End_Of_File (Input_File) loop

            Read(Input_File, Data, Last); -- eat a chunk
           
            for Elem of Data (1..Last) loop
                C := Integer(Elem);

                Current_Key := (Prefix_Index => Current_Code, Suffix_Code => C);
                Cursor := Dictionnary.Find(Current_Key);

                if Cursor /= Encoding_Hashed_Maps.No_Element then
                    Current_Code := Element(Cursor);

                else
                    if Long_Integer(Dictionnary_Length) < Long_Integer(2 ** Max_Bits_Pack_Size) - 1 then
                        Dictionnary.Insert(Current_Key, Dictionnary_Length);
                        Dictionnary_Length := Dictionnary_Length + 1;
                    end if;

                    Index := Current_Code;

                    Remaining_Bits_To_Pack_For_Current_Index := Bits_Pack_Size;

                    Bits_Packing_Loop:
                    while True loop
                        Bit_Shift_Size := Remaining_Bits_To_Pack_For_Current_Index - Byte_Free_Bits;

                        Byte_Value_To_Append := Integer(Shift_Right(Unsigned_32(Index),Bit_Shift_Size));

                        Index := Index mod (2 ** Bit_Shift_Size);

                        Remaining_Bits_To_Pack_For_Current_Index := Bit_Shift_Size;

                        Byte_Value := Integer(Shift_Left(Unsigned_32(Byte_Value), Byte_Free_Bits));
                        Byte_Value := Integer(Unsigned_32(Byte_Value) or Unsigned_32(Byte_Value_To_Append));

                        Write(Output_File,Character'Val(Byte_Value));
                        --Put(Byte_To_Write'Image);

                        Byte_Free_Bits := 8;

                        if Remaining_Bits_To_Pack_For_Current_Index >= 8 then
                            Byte_Value := 0;
                        else
                            Byte_Free_Bits := 8 - Remaining_Bits_To_Pack_For_Current_Index;
                            Byte_Value := Index;
                            exit Bits_Packing_Loop;
                        end if;

                    end loop Bits_Packing_Loop;
                    
                    if Long_Integer(Dictionnary_Length) >= Long_Integer(2 ** Bits_Pack_Size) and Bits_Pack_Size < Max_Bits_Pack_Size then
                        Bits_Pack_Size := Bits_Pack_Size + 1;
                    end if;

                    Current_Code := C;
                end if;
            end loop;
        end loop;

        -- Not forgetting to encode remaining bytes.
        -- We are forcibly on Current_Code contained in Dictionnary
        -- So simply encode Current_Code index.
        Last_Index := Current_Code;
        Remaining_Bits_To_Pack_For_Current_Index := Bits_Pack_Size;

        Last_Bits_Packing_Loop:
        while True loop
            Bit_Shift_Size := Remaining_Bits_To_Pack_For_Current_Index - Byte_Free_Bits;

            Byte_Value_To_Append := Integer(Shift_Right(Unsigned_32(Last_Index),Bit_Shift_Size));

            Last_Index := Last_Index mod (2 ** Bit_Shift_Size);

            Remaining_Bits_To_Pack_For_Current_Index := Bit_Shift_Size;

            Byte_Value := Integer(Shift_Left(Unsigned_32(Byte_Value), Byte_Free_Bits));
            Byte_Value := Integer(Unsigned_32(Byte_Value) or Unsigned_32(Byte_Value_To_Append));

            Write(Output_File,Character'Val(Byte_Value));
            --Put(">>" & Byte_To_Write'Image);

            Byte_Free_Bits := 8;

            if Remaining_Bits_To_Pack_For_Current_Index >= 8 then
                Byte_Value := 0;
            else
                Byte_Free_Bits := 8 - Remaining_Bits_To_Pack_For_Current_Index;
                Byte_Value := Last_Index;
                Byte_Value := Integer(Shift_Left(Unsigned_32(Byte_Value),Byte_Free_Bits));
                Write(Output_File,Character'Val(Byte_Value));
                -- TODO: do i need to pad with zero's behind?
                exit Last_Bits_Packing_Loop;
            end if;

        end loop Last_Bits_Packing_Loop;

        Close(Input_File);
        Close(Output_File);

    end LZW_Compress;

    procedure LZW_Decompress (Input_File_Path: String; Output_File_Path: String; Max_Bits_Pack_Size: Integer) is
        use Character_IO;
        Input_File: Character_IO.File_Type;
        Output_File: Character_IO.File_Type;

        Dictionnary: Decoding_Hashed_Maps.Map;

        -- TODO: Allow read size to be flexible for speed increase.
        -- For now we simply read Input_File byte by byte.
        C: Character; -- current read byte from encoded file (char)
        Current_String: Unbounded_String;

        Bits_Pack_Size: Integer := 9;
        Remaining_Bits_To_Unpack_For_Current_Index: Integer := Bits_Pack_Size;

        Index: Integer := 0;

        New_Entry : Unbounded_String;
    begin
        Initialize_Decoding_Dictionnary(Dictionnary);

        Open (File => Input_File, 
              Mode => In_File, 
              Name => Input_File_Path);

        Create (File => Output_File,
                Mode => Out_File,
                Name => Output_File_Path);

        -- Decode first character (decoding must caught up, encoding is one step ahead)
        while True loop

            Read(Input_File, C);
            Remaining_Bits_To_Unpack_For_Current_Index := Remaining_Bits_To_Unpack_For_Current_Index - 8;

            if Remaining_Bits_To_Unpack_For_Current_Index > 0 then
                Index := Index + Integer(Shift_Left(Unsigned_32(Character'Pos(C)),Remaining_Bits_To_Unpack_For_Current_Index));
            else
                Index := Index + Integer(Shift_Right(Unsigned_32(Character'Pos(C)),abs Remaining_Bits_To_Unpack_For_Current_Index));
                --Put(Index'Image & " ");

                Current_String := Dictionnary(Index);
                for I in 1..Length(Current_String) loop
                    Write(Output_File, Element(Current_String,I));
                end loop;

                if Dictionnary.Length >= (2 ** Bits_Pack_Size) - 1 then
                    Bits_Pack_Size := Bits_Pack_Size + 1;
                end if;

                Index := Integer(Character'Pos(C)) mod 2 ** (abs Remaining_Bits_To_Unpack_For_Current_Index);
                Index := Integer(Shift_Left(Unsigned_32(Index),Bits_Pack_Size - abs Remaining_Bits_To_Unpack_For_Current_Index ));

                Remaining_Bits_To_Unpack_For_Current_Index := Bits_Pack_Size - abs Remaining_Bits_To_Unpack_For_Current_Index;

                exit; -- remember we need first char only

            end if;
        end loop;

        -- and go on
        while Remaining_Bits_To_Unpack_For_Current_Index > 0 and not End_Of_File(Input_File) loop

            if Remaining_Bits_To_Unpack_For_Current_Index = 0 then
                Remaining_Bits_To_Unpack_For_Current_Index := Bits_Pack_Size;
            end if;

            Read(Input_File, C);
            Remaining_Bits_To_Unpack_For_Current_Index := Remaining_Bits_To_Unpack_For_Current_Index - 8;

            if Remaining_Bits_To_Unpack_For_Current_Index > 0 then
                Index := Index + Integer(Shift_Left(Unsigned_32(Character'Pos(C)),Remaining_Bits_To_Unpack_For_Current_Index));

            else
                Index := Index + Integer(Shift_Right(Unsigned_32(Character'Pos(C)),abs Remaining_Bits_To_Unpack_For_Current_Index));
                --Put(Index'Image & " ");

                if Dictionnary.Contains(Index) then
                    New_Entry := Dictionnary(Index);

                elsif Index = Integer(Dictionnary.Length) then
                    New_Entry := Current_String & Element(Current_String,1); -- this is how you access a char in unbounded string... lol

                else
                    raise Exceptions.Unreachable with "Invalid index";

                end if;

                --Put(To_String(New_Entry));
                for I in 1..Length(New_Entry) loop
                    Write(Output_File, Element(New_Entry,I));
                end loop;

                if Long_Integer(Dictionnary.Length) < Long_Integer(2 ** Max_Bits_Pack_Size) - 1 then
                    Dictionnary.Include(Integer(Dictionnary.Length), Current_String & Element(New_Entry,1));
                end if;
                Current_String := New_Entry;

                if Long_Integer(Dictionnary.Length) >= Long_Integer(2 ** Bits_Pack_Size) - 1 and Bits_Pack_Size < Max_Bits_Pack_Size then
                    Bits_Pack_Size := Bits_Pack_Size + 1;
                end if;

                -- new Index for next iteration
                Index := Integer(Character'Pos(C)) mod 2 ** (abs Remaining_Bits_To_Unpack_For_Current_Index);
                Index := Integer(Shift_Left(Unsigned_32(Index),Bits_Pack_Size - abs Remaining_Bits_To_Unpack_For_Current_Index ));

                Remaining_Bits_To_Unpack_For_Current_Index := Bits_Pack_Size - abs Remaining_Bits_To_Unpack_For_Current_Index;

            end if;
        end loop;

        Close(Input_File);
        Close(Output_File);

    end LZW_Decompress;

end LZW;
