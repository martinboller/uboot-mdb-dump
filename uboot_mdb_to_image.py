#    Small hackish script to convert an U-Boot memdump to a binary image
#
#    Copyright (C) 2015  Simon Baatz
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License along
#    with this program; if not, write to the Free Software Foundation, Inc.,
#    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
# 
#    Significant changes made by Luca Bongiorni
#    2026-01-19 some changes to make it run under Python 3.13:
#    Variable data declared outside Try loop and : not escaped in RegEx


from argparse import ArgumentParser
from re import compile
from os import devnull
from sys import stdout, stderr, __stdout__, __stderr__
from tqdm import tqdm
from binwalk import scan


class Utility():
    def __init__(self):
        self.args = self.get_args()
        return


    def get_args(self):
        parser = ArgumentParser()
        parser.add_argument(
            "logfile"
        )
        parser.add_argument(
            "-l",
            "--line_length",
            help    = "Bytes in each line",
            default = 0x10
        )
        parser.add_argument(
            "-o",
            "--outfile",
            help    = "File to store the results",
            default = "output.bin"
        )
        return vars(parser.parse_args())




class MDB_Converter():
    def __init__(self, **kwargs):
        self.logfile = kwargs["logfile"]
        self.outfile = kwargs["outfile"]

        self.bytes_in_line   = kwargs["bytes_in_line"]
        self.pattern         = compile("^[0-9a-fA-F]{8}:")
        self.logfile_content = []
        self.binary_data     = []


    def disable_output(self):
        stdout = open(devnull, "w")
        stderr = open(devnull, "w")
        return


    def enable_output(self):
        stdout = __stdout__
        stderr = __stderr__
        return


    def read_log(self):
        with open(self.logfile, 'r') as fptr:
            self.logfile_content = fptr.readlines()
        return


    def write_image(self):
        with open(self.outfile, 'wb') as fptr:
            fptr.write(self.binary_data)


    def extract_image(self):
        print("[+] Extracting...")
        self.disable_output()
        scan(
            self.outfile,
            signature = True,
            quiet = True,
            extract = True
        )
        print("\033[H\033[J", end="")
        self.enable_output()
        print(f"[+] Image extracted to {self.outfile}")
        return

    def convert_log(self):
        c_addr     = None
        hex_to_chr = {}
        line_count = 0

        # Find the starting point of the dump
        for i, line in enumerate(self.logfile_content):
            if "md 0x" in line or "md.b 0x" in line:
                line_count = i + 1
                break
        
        # Slice the content to start after the command
        self.logfile_content = self.logfile_content[line_count:]

        print("[+] Repairing image...")
        abs_count = len(self.logfile_content)
        
        for line in tqdm(self.logfile_content):
            abs_count -= 1
            line = line.strip() # Remove newline and extra whitespace
            
            # Skip empty lines or lines that don't look like hex dumps
            if not self.pattern.match(line):
                continue

            try:
                # 1. Attempt to split the hex data from the ASCII sidebar
                if "    " in line:
                    data_str, ascii_data = line.split("    ", maxsplit=1)
                else:
                    # Fallback for lines that might be malformed or missing the 4-space separator
                    data_str = line
                    ascii_data = ""

                # 2. Split the address from the hex bytes
                straddr, strdata = data_str.split(":", 1)
                addr = int(straddr, 16)
                
                # Convert the hex string to actual bytes
                # We strip spaces to handle "AA BB CC" or "AABBCC"
                data = bytes.fromhex(strdata.replace(" ", ""))

            except ValueError:
                # If the line is totally mangled, skip it or handle specifically
                print(f"\n[!] Skipping mangled line: {line}")
                continue

            # Now 'data' is guaranteed to exist if we reached this point
            if c_addr is not None and addr != c_addr + self.bytes_in_line:
                print(f"\n[!] Unexpected address jump at 0x{straddr}")
            
            c_addr = addr

            # Final line repair logic (if the dump ended prematurely)
            if abs_count == 0 and len(data) < self.bytes_in_line:
                print(f"\n[+] Padding final line...")
                data = data.ljust(self.bytes_in_line, b"\x00")

            self.binary_data.append(data)

        self.binary_data = b''.join(self.binary_data)
        return


def main():
    #args = Utility.get_args()
    utilities = Utility()

    mdb_converter = MDB_Converter(
        logfile = utilities.args["logfile"],
        outfile = utilities.args["outfile"],
        bytes_in_line = utilities.args["line_length"]
    )

    mdb_converter.read_log()
    mdb_converter.convert_log()
    mdb_converter.write_image()
    mdb_converter.extract_image()
    return

if __name__ == '__main__':
    exit(main())
