with Ada.Containers; use Ada.Containers;
with Ada.Containers.Indefinite_Hashed_Maps;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Streams; use Ada.Streams;
with Ada.Streams.Stream_IO; use Ada.Streams.Stream_IO;
with Ada.Strings.Unbounded.Hash;
with Ada.Sequential_IO;
with Interfaces; use Interfaces;
with Ada.Exceptions; use Ada.Exceptions;

package Lzw is

    -- https://learn.adacore.com/courses/intro-to-ada/chapters/exceptions.html
    package Exceptions is
        Unreachable : exception;
    end Exceptions;

    package Character_IO is new Ada.Sequential_IO (Character);

    function Integer_Hash (Key: in Integer) return Hash_Type;

    package Encoding_Hashed_Maps is new Ada.Containers.Indefinite_Hashed_Maps
        (Key_Type        => Unbounded_String,
         Element_Type    => Integer,
         Hash            => Ada.Strings.Unbounded.Hash,
         Equivalent_Keys => "=");

    package Decoding_Hashed_Maps is new Ada.Containers.Indefinite_Hashed_Maps
        (Key_Type        => Integer,
         Element_Type    => Unbounded_String,
         Hash            => Integer_Hash,
         Equivalent_Keys => "=");

    procedure Initialize_Encoding_Dictionnary (D: out Encoding_Hashed_Maps.Map);
    procedure Initialize_Decoding_Dictionnary (D: out Decoding_Hashed_Maps.Map);
    procedure Encode_Lzw (Input_File_Path: in String; Output_File_Path: in String; Max_Bits_Pack_Size: in Integer);
    procedure Decode_Lzw (Input_File_Path: in String; Output_File_Path: in String; Max_Bits_Pack_Size: in Integer);

end Lzw;
