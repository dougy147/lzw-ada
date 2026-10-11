with Ada.Text_IO; use Ada.Text_IO;
with Ada.Sequential_IO;

with Ada.Containers; use Ada.Containers;
with Ada.Containers.Vectors;
with Ada.Containers.Indefinite_Hashed_Maps;

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Unbounded.Hash;

with Ada.Directories; use Ada.Directories;

with Interfaces; use Interfaces;

function Lzw return Integer is

    package Character_IO is new Ada.Sequential_IO (Character);

    package Encoding_Hashed_Maps is new Ada.Containers.Indefinite_Hashed_Maps
        (Key_Type        => Unbounded_String,
         Element_Type    => Long_Long_Integer,
         Hash            => Ada.Strings.Unbounded.Hash,
         Equivalent_Keys => "=");

    function Long_Long_Integer_Hash (Key: Long_Long_Integer) return Hash_Type is
    begin
        return Hash_Type(Key);
    end Long_Long_Integer_Hash;
    
    package Decoding_Hashed_Maps is new Ada.Containers.Indefinite_Hashed_Maps
        (Key_Type        => Long_Long_Integer,
         Element_Type    => Unbounded_String,
         Hash            => Long_Long_Integer_Hash,
         Equivalent_Keys => "=");

    procedure Initialize_Alphabet_Encoding (H: out Encoding_Hashed_Maps.Map) is
        W:  Unbounded_String; -- TODO: find a better name
    begin
        for I in 0..255 loop
            W := To_Unbounded_String("") & Character'Val(I);
            H.Include(W, Long_Long_Integer(I));
        end loop;
    end;
    
    procedure Initialize_Alphabet_Decoding (H: out Decoding_Hashed_Maps.Map) is
        W:  Unbounded_String; -- TODO: find a better name
    begin
        for I in 0..255 loop
            W := To_Unbounded_String("") & Character'Val(I);
            H.Include(Long_Long_Integer(I),W);
        end loop;
    end;
    
    package Index_Vectors is new Ada.Containers.Vectors
        (Index_Type   => Positive,
         Element_Type => Long_Long_Integer);

    function Encode_Lzw_To_Index_Vector (File_Path: String) return Index_Vectors.Vector is
        use Character_IO;
        File: Character_IO.File_Type;
        C: Character; -- current read byte from file (char)

        W:  Unbounded_String; -- TODO: find a better name
        WC: Unbounded_String;

        H: Encoding_Hashed_Maps.Map;

        Encoded: Index_Vectors.Vector;
    begin

        Initialize_Alphabet_Encoding(H);

        Open (File => File, Mode => In_File, Name => File_Path);

        --Put("Raw input: ");
        while not End_Of_File (File) loop
            Read(File, C); 
            --Put(C);
            WC := W & C;
            if H.Contains(WC) then
                W := WC;
            else
                H.Include(WC, Long_Long_Integer(H.Length));
                --Put_Line(To_String(WC));
                Encoded.Append(H(W));
                W := To_Unbounded_String("") & C;
            end if;
        end loop;
        Encoded.Append(H(W));

        Put("Encoded : ");
        for Index of Encoded loop
            Put(Index'Image & " ");
        end loop;
        Put_Line("");

        --Put_Line("H.Length = " & H.Length'Image);
        return Encoded;
    end Encode_Lzw_To_Index_Vector;

    procedure Pack_Encoded_To_File(Encoded: Index_Vectors.Vector; Output_File_Path: String) is

        use Character_IO;
        Output_File: Character_IO.File_Type;


        Bits_To_Pack: Integer := 9;
        Bits_To_Pack_Current: Integer;

        Byte_Remaining_Bits : Integer := 8;
        S : Integer;
        Byte_Current_Value  : Long_Long_Integer := 0;

        X: Long_Long_Integer;
        Prev_V_To_Pack : Long_Long_Integer;
        V_To_Pack      : Long_Long_Integer;
        Byte_To_Write  : Long_Long_Integer;
    begin

        Create(File => Output_File, Mode => Out_File, Name => Output_File_Path);

        --Put("Packed : ");
        for Index of Encoded loop
            X := Index;

            if X >= 2 ** Bits_To_Pack then
                Bits_To_Pack := Bits_To_Pack + 1;
                Put_Line("Packing size = " & Bits_To_Pack'Image & " bits");
            end if;

            Bits_To_Pack_Current := Bits_To_Pack;
            Pack_Loop:
            while True loop
                S := Bits_To_Pack_Current - Byte_Remaining_Bits; -- Shifting value
                V_To_Pack := Long_Long_Integer(Shift_Right(Unsigned_64(X),S));
                X := X mod (2 ** S);
                Bits_To_Pack_Current := S;
                Prev_V_To_Pack := Long_Long_Integer(Shift_Left(Unsigned_64(Byte_Current_Value), Byte_Remaining_Bits));
                Byte_To_Write  := Long_Long_Integer(Unsigned_64(Prev_V_To_Pack) or Unsigned_64(V_To_Pack));
                --Put(Byte_To_Write'Image & " ");
                --Put_Line(Prev_V_To_Pack'Image & " | " & V_To_Pack'Image & " => " & Byte_To_Write'Image & " ");
                Write(Output_File,Character'Val(Byte_To_Write));
                Byte_Remaining_Bits := 8;
                if Bits_To_Pack_Current >= 8 then
                    Byte_Current_Value := 0;
                else
                    Byte_Remaining_Bits := 8 - Bits_To_Pack_Current;
                    Byte_Current_Value := X;
                    exit Pack_Loop;
                end if;
            end loop Pack_Loop;

        end loop;

        if Byte_Remaining_Bits /= 8 then
            Byte_To_Write := Long_Long_Integer(Shift_Left(Unsigned_64(Byte_Current_Value),Byte_Remaining_Bits));
            Write(Output_File,Character'Val(Byte_To_Write));
            --Put(Byte_To_Write'Image & " ");
        end if;

        Close(Output_File);

    end Pack_Encoded_To_File;


    procedure Encode_Lzw (Input_File_Path: String; Output_File_Path: String) is
        use Character_IO;
        Input_File: Character_IO.File_Type;
        Output_File: Character_IO.File_Type;
        C: Character; -- current read byte from file (char)

        W:  Unbounded_String; -- TODO: find a better name
        WC: Unbounded_String;

        H: Encoding_Hashed_Maps.Map;

        Bits_To_Pack: Integer := 9;
        Bits_To_Pack_Current: Integer;

        Byte_Remaining_Bits : Integer := 8;
        S : Integer;
        Byte_Current_Value: Long_Long_Integer := 0;

        X: Long_Long_Integer;
        Prev_V_To_Pack : Long_Long_Integer;
        V_To_Pack      : Long_Long_Integer;
        Byte_To_Write  : Long_Long_Integer;
    begin

        Initialize_Alphabet_Encoding(H);

        Open (File => Input_File, Mode => In_File, Name => Input_File_Path);
        Create(File => Output_File, Mode => Out_File, Name => Output_File_Path);

        --Put("Raw input: ");
        while not End_Of_File (Input_File) loop
            Read(Input_File, C); 
            WC := W & C;
            if H.Contains(WC) then
                W := WC;
            else
                H.Include(WC, Long_Long_Integer(H.Length));

                X := Long_Long_Integer(H(W));
                --Put(To_String(W));

                Bits_To_Pack_Current := Bits_To_Pack;

                Pack_Loop:
                while True loop
                    S := Bits_To_Pack_Current - Byte_Remaining_Bits; -- Shifting value
                    V_To_Pack := Long_Long_Integer(Shift_Right(Unsigned_64(X),S));
                    X := X mod (2 ** S);
                    Bits_To_Pack_Current := S;
                    Prev_V_To_Pack := Long_Long_Integer(Shift_Left(Unsigned_64(Byte_Current_Value), Byte_Remaining_Bits));
                    Byte_To_Write  := Long_Long_Integer(Unsigned_64(Prev_V_To_Pack) or Unsigned_64(V_To_Pack));

                    Write(Output_File,Character'Val(Byte_To_Write));
                    --Put(Byte_To_Write'Image);

                    Byte_Remaining_Bits := 8;

                    if Bits_To_Pack_Current >= 8 then
                        Byte_Current_Value := 0;
                    else
                        Byte_Remaining_Bits := 8 - Bits_To_Pack_Current;
                        Byte_Current_Value := X;
                        exit Pack_Loop;
                    end if;

                end loop Pack_Loop;
                
                if H.Length >= 2 ** Bits_To_Pack then
                    Bits_To_Pack := Bits_To_Pack + 1;
                end if;

                W := To_Unbounded_String("") & C;
            end if;
        end loop;

        -- just for last value
        X := Long_Long_Integer(H(W));
        Bits_To_Pack_Current := Bits_To_Pack;

        Pack_Loop2:
        while True loop
            S := Bits_To_Pack_Current - Byte_Remaining_Bits; -- Shifting value
            V_To_Pack := Long_Long_Integer(Shift_Right(Unsigned_64(X),S));
            X := X mod (2 ** S);
            Bits_To_Pack_Current := S;
            Prev_V_To_Pack := Long_Long_Integer(Shift_Left(Unsigned_64(Byte_Current_Value), Byte_Remaining_Bits));
            Byte_To_Write  := Long_Long_Integer(Unsigned_64(Prev_V_To_Pack) or Unsigned_64(V_To_Pack));

            Write(Output_File,Character'Val(Byte_To_Write));
            Byte_Remaining_Bits := 8;

            if Bits_To_Pack_Current >= 8 then
                Byte_Current_Value := 0;
            else
                Byte_Remaining_Bits := 8 - Bits_To_Pack_Current;
                Byte_Current_Value := X;
                exit Pack_Loop2;
            end if;

        end loop Pack_Loop2;

        Close(Input_File);
        Close(Output_File);

    end Encode_Lzw;
    
    procedure Decode_Lzw (Encoded_File_Path: String) is
        use Character_IO;
        Encoded_File: Character_IO.File_Type;
        Byte: Character; -- current read byte from encoded file (char)

        C : Character;

        Bits_To_Read: Integer := 9;
        Remaining_Bits_To_Read: Integer := Bits_To_Read;
        V: Long_Long_Integer := 0; -- Will correspond to the value of an index in dictionnary

        W: Unbounded_String;
        Decoded: Unbounded_String;
        New_Entry: Unbounded_String;

        H: Decoding_Hashed_Maps.Map;
    begin
        Initialize_Alphabet_Decoding(H);
        Open (File => Encoded_File, Mode => In_File, Name => Encoded_File_Path);

        -----------------------------------------
        while True loop
            Read(Encoded_File, Byte);
            Remaining_Bits_To_Read := Remaining_Bits_To_Read - 8;

            if Remaining_Bits_To_Read > 0 then
                V := V + Long_Long_Integer(Shift_Left(Unsigned_64(Character'Pos(Byte)),Remaining_Bits_To_Read));
            else
                V := V + Long_Long_Integer(Shift_Right(Unsigned_64(Character'Pos(Byte)),abs Remaining_Bits_To_Read));
                Put(V'Image & " ");

                W := H(V);
                Decoded := W;

                if H.Length >= (2 ** Bits_To_Read) - 1 then
                    Bits_To_Read := Bits_To_Read + 1;
                    Put_Line("H.Length = " & H.Length'Image & " ; Unpacking size = " & Bits_To_Read'Image & " bits");
                end if;

                -- new V for next iteration
                V := Long_Long_Integer(Character'Pos(Byte)) mod 2 ** (abs Remaining_Bits_To_Read);
                V := Long_Long_Integer(Shift_Left(Unsigned_64(V),Bits_To_Read - abs Remaining_Bits_To_Read ));
                Remaining_Bits_To_Read := Bits_To_Read - abs Remaining_Bits_To_Read;
                exit;
            end if;
        end loop;
        ----------------------------------

        Put("Decoded : ");

        while Remaining_Bits_To_Read > 0 and not End_Of_File(Encoded_File) loop

            if Remaining_Bits_To_Read = 0 then
                Remaining_Bits_To_Read := Bits_To_Read;
            end if;

            Read(Encoded_File, Byte);
            Remaining_Bits_To_Read := Remaining_Bits_To_Read - 8;

            if Remaining_Bits_To_Read > 0 then
                V := V + Long_Long_Integer(Shift_Left(Unsigned_64(Character'Pos(Byte)),Remaining_Bits_To_Read));
            else
                V := V + Long_Long_Integer(Shift_Right(Unsigned_64(Character'Pos(Byte)),abs Remaining_Bits_To_Read));
                --Put(V'Image & " ");

                -- retrieve string corresponding to this index
                if H.Contains(V) then
                    New_Entry := H(V);
                    --Put("(" & To_String(New_Entry) & "," & V'Image & ")");
                --elsif V = Long_Long_Integer(H.Length) then
                else
                    New_Entry := W & Element(W,1); -- this is how you access a char in unbounded string... lol
                    --Put("=>> " & To_String(New_Entry));
                end if;

                --Put(To_String(New_Entry);
                Decoded := Decoded & New_Entry;
                H.Include(Long_Long_Integer(H.Length), W & Element(New_Entry,1));
                W := New_Entry;

                if H.Length >= (2 ** Bits_To_Read) - 1 then
                    Bits_To_Read := Bits_To_Read + 1;
                    --Put_Line("H.Length = " & H.Length'Image & " ; Unpacking size = " & Bits_To_Read'Image & " bits");
                end if;

                -- new V for next iteration
                V := Long_Long_Integer(Character'Pos(Byte)) mod 2 ** (abs Remaining_Bits_To_Read);
                V := Long_Long_Integer(Shift_Left(Unsigned_64(V),Bits_To_Read - abs Remaining_Bits_To_Read ));
                Remaining_Bits_To_Read := Bits_To_Read - abs Remaining_Bits_To_Read;

            end if;
        end loop;

        --Put(V'Image & " ");
        if H.Contains(V) then
            New_Entry := H(V);
        else
            New_Entry := W & Element(W,1); -- this is how you access a char in unbounded string... lol
        end if;
        Decoded := Decoded & New_Entry;

        --Put_Line("");
        --Put_Line("Decoded String: " & To_String(Decoded));
        Put_Line(To_String(Decoded));

        Close(Encoded_File);
    end Decode_Lzw;

begin

    --Pack_Encoded_To_File(Encode_Lzw("/home/luc/stack/pacman.log"), "pacman.lzw");
    
    --Encode_Lzw("tobeornottobe.txt","tobeornottobe.lzw");
    --Decode_Lzw("tobeornottobe.lzw");

    --Encode_Lzw("README.md", "readme.lzw");
    --Decode_Lzw("readme.lzw");

    --Encode_Lzw("/home/luc/stack/pacman.log", "pacman.lzw");
    Decode_Lzw("pacman.lzw");
    return 0;
end Lzw;
