#!/usr/bin/env tl

rbgToBin = red, green, blue ->
    packed = red << 16 | green << 8 | blue
    buf = Buffer.new
    (24 // 3).times: n ->
        triple = (packed >> (24 - n * 3)) & 0b111
        pulse = { triple == 0b000 }: 36 # + 1 + 8 + 64
                { triple == 0b001 }: 36 +         64
                { triple == 0b010 }: 36 +     8
                { triple == 0b011 }: 36 +     8 + 64
                { triple == 0b100 }: 36 + 1
                { triple == 0b101 }: 36 + 1 +     64
                { triple == 0b110 }: 36 + 1 + 8
                { triple == 0b111 }: 36 + 1 + 8 + 64
        buf.write(pulse)
        buf.read

rbgToStim = red, green, blue, offset ->
    offset = offset or 0
    packed = red << 16 | green << 8 | blue
    buf = Buffer.new
    (24).times: n ->
        bit = (packed >> (24 - n)) & 0b1
        len = 1 + bit
        buf.write "$(offset + n * 3 * 208), 1, "
        buf.write "$(offset + n * 3 * 208 + len * 208), 0,\n"
    return buf.readString

print repr rbgToBin(255, 0, 128)
print rbgToStim(255, 0, 128, 208 * 3 * 32)
