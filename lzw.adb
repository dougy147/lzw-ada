with Ada.Text_IO; use Ada.Text_IO;
with Ada.Sequential_IO;

with Ada.Containers; use Ada.Containers;
with Ada.Containers.Vectors;
with Ada.Containers.Indefinite_Hashed_Maps;

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Strings.Unbounded.Hash;

with Ada.Directories; use Ada.Directories;

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

    procedure Encode_Lzw (File_Path: String) is
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

        Put("Raw input: ");
        while not End_Of_File (File) loop
            Read(File, C); 
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

        --Put_Line("");
        --Put("Encoded : ");
        --for Index of Encoded loop
        --    Put(Index'Image & " ");
        --end loop;
        --Put_Line("");

        Put_Line("H.Length = " & H.Length'Image);
    end Encode_Lzw;


begin

    Encode_Lzw("tobeornottobe.txt");
    --Encode_Lzw("/home/luc/stack/pacman.log");

    return 0;
end Lzw;

-- Check sources:
-- https://vapier.github.io/ncompress/

