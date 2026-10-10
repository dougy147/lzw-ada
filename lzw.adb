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

    procedure Initialize_Alphabet (H: out Encoding_Hashed_Maps.Map) is
        W:  Unbounded_String; -- TODO: find a better name
    begin
        for I in 0..255 loop
            W := To_Unbounded_String("") & Character'Val(I);
            H.Include(W, Long_Long_Integer(I));
        end loop;
    end;
    
    package Index_Vectors is new Ada.Containers.Vectors
        (Index_Type   => Positive,
         Element_Type => Long_Long_Integer);

    function Encode_Lzw (File_Path: String) return Index_Vectors.Vector is
        use Character_IO;
        File: Character_IO.File_Type;
        C: Character; -- current read byte from file (char)

        W:  Unbounded_String; -- TODO: find a better name
        WC: Unbounded_String;

        H: Encoding_Hashed_Maps.Map;

        Encoded: Index_Vectors.Vector;
    begin

        Initialize_Alphabet(H);

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

        --Put("Encoded : ");
        --for Index of Encoded loop
        --    Put(Index'Image & " ");
        --end loop;
        --Put_Line("");

        --Put_Line("H.Length = " & H.Length'Image);
        return Encoded;
    end Encode_Lzw;

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
    
    Encoded: Index_Vectors.Vector;
begin

    --Encoded := Encode_Lzw("tobeornottobe.txt");
    Encoded := Encode_Lzw("/home/luc/stack/pacman.log");
    Pack_Encoded_To_File(Encoded, "encoded.lzw");

    return 0;
end Lzw;

-- Check sources:
-- https://vapier.github.io/ncompress/

