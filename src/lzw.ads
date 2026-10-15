with Ada.Containers; use Ada.Containers;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Streams; use Ada.Streams;
with Ada.Streams.Stream_IO; use Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded.Hash;
with Ada.Sequential_IO;
with Interfaces; use Interfaces;
with Ada.Exceptions; use Ada.Exceptions;

package LZW is

    -- https://learn.adacore.com/courses/intro-to-ada/chapters/exceptions.html
    package Exceptions is
        Unreachable : exception;
    end Exceptions;

    -- Encoded_Key = (Current_Substring_Index_In_Dictionnary, Suffix_Char_Code)
    type Encoded_Key is record
        Prefix_Index : Integer;
        Suffix_Code  : Integer;
    end record;

    package Character_IO is new Ada.Sequential_IO (Character);

    function Encoded_Key_Hash (Key: in Encoded_Key) return Hash_Type;
    function Encoded_Key_Equivalence (Key_A, Key_B: in Encoded_Key) return Boolean;
    function Integer_Hash (Key: in Integer) return Hash_Type;

    package Encoding_Hashed_Maps is new Ada.Containers.Indefinite_Hashed_Maps
        (Key_Type        => Encoded_Key,
         Element_Type    => Integer,
         Hash            => Encoded_Key_Hash,
         Equivalent_Keys => Encoded_Key_Equivalence);

    package Decoding_Hashed_Maps is new Ada.Containers.Indefinite_Hashed_Maps
        (Key_Type        => Integer,
         Element_Type    => Unbounded_String,
         Hash            => Integer_Hash,
         Equivalent_Keys => "=");

    procedure Initialize_Encoding_Dictionnary (D: out Encoding_Hashed_Maps.Map);
    procedure Initialize_Decoding_Dictionnary (D: out Decoding_Hashed_Maps.Map);
    procedure LZW_Compress (Input_File_Path: in String; Output_File_Path: in String; Max_Bits_Pack_Size: in Integer);
    procedure LZW_Decompress (Input_File_Path: in String; Output_File_Path: in String; Max_Bits_Pack_Size: in Integer);

end LZW;
