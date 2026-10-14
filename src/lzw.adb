package body Lzw is

    function Integer_Hash (Key: Integer) return Hash_Type is
    begin
        return Hash_Type(Key);
    end Integer_Hash;

    procedure Initialize_Encoding_Dictionnary (D: out Encoding_Hashed_Maps.Map) is
        Current_String:  Unbounded_String;
    begin
        for I in 0..255 loop
            Current_String := To_Unbounded_String("") & Character'Val(I);
            D.Include(Current_String, Integer(I));
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
    
    procedure Encode_Lzw (Input_File_Path: String; Output_File_Path: String; Max_Bits_Pack_Size: Integer) is
        -- Read input file bufferized (~some small perf increase)
        Input_File: Stream_IO.File_Type;
        Data: Stream_Element_Array (1 .. 1024 * 1024); -- 1Mb chunks
        Last: Stream_Element_Offset;

        use Character_IO;
        Output_File: Character_IO.File_Type;

        Dictionnary: Encoding_Hashed_Maps.Map;

        -- TODO: Allow read size to be flexible for speed increase.
        -- For now we simply read Input_File byte by byte.
        C: Character; -- current byte read from input file
        Current_String           : Unbounded_String;
        Current_String_Plus_Char : Unbounded_String;
 
        -- TODO: We start encoding indexes in 9-bits and have
        -- no upper limit. Hitting a 64-bits index limits seems... highly improbable -- but we should certainly limit dictionnary length to ease on memory.
        Bits_Pack_Size: Integer := 9;
        Remaining_Bits_To_Pack_For_Current_Index: Integer;

        -- NOTE: Remember we read Input_File byte by byte.
        -- Hence we use this variable name and this 8 value. <|:^)
        Byte_Free_Bits : Integer := 8;

        Byte_Value           : Integer := 0;
        Byte_Value_To_Append : Integer;

        Index      : Integer;
        Last_Index : Integer;

        Bit_Shift_Size : Integer; -- for readability

    begin

        Initialize_Encoding_Dictionnary(Dictionnary);

        Open (File => Input_File, 
              Mode => In_File, 
              Name => Input_File_Path);

        Create(File => Output_File, 
               Mode => Out_File,
               Name => Output_File_Path);

        while not End_Of_File (Input_File) loop

            Read(Input_File, Data, Last); -- eat a chunk

            for Elem of Data (1..Last) loop
                C := Character'Val(Elem);

                Current_String_Plus_Char := Current_String & C;

                if Dictionnary.Contains(Current_String_Plus_Char) then
                    Current_String := Current_String_Plus_Char;

                else
                    if Long_Integer(Dictionnary.Length) < Long_Integer(2 ** Max_Bits_Pack_Size) - 1 then
                        Dictionnary.Include(Current_String_Plus_Char, Integer(Dictionnary.Length));
                    end if;

                    Index := Dictionnary(Current_String);

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
                    
                    if Long_Integer(Dictionnary.Length) >= Long_Integer(2 ** Bits_Pack_Size) and Bits_Pack_Size < Max_Bits_Pack_Size then
                        Bits_Pack_Size := Bits_Pack_Size + 1;
                    end if;

                    Current_String := To_Unbounded_String("") & C;
                end if;
            end loop;
        end loop;

        -- Not forgetting to encode remaining bytes.
        -- We are forcibly on Current_String contained in Dictionnary
        -- So simply encode Current_String index.
        Last_Index := Dictionnary(Current_String);
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

    end Encode_Lzw;

    procedure Decode_Lzw (Input_File_Path: String; Output_File_Path: String; Max_Bits_Pack_Size: Integer) is
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

    end Decode_Lzw;

end Lzw;
