.ORG 0
.BASE 0
.DB $4e, $45, $53, $1a ; Magic string that always begins an iNES header
.DB $02        ; Number of 16KB PRG-ROM banks
.DB $01        ; Number of 8KB CHR-ROM banks
.DB @00000000  ; Horizontal mirroring, no save RAM, no mapper
.DB @00000000  ; No special-case flags set, no mapper
.DB $00        ; No PRG-RAM present
.DB $00        ; NTSC format
