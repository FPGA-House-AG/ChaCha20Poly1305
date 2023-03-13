from cryptography.hazmat.primitives.asymmetric import x25519

class ECDH_key_generator():

    def __init__(self):
        self.bits = 255
        self.p = 2**255 - 19
        self.a24 = 121665
        self.a48 = 486662
        self.a = int.from_bytes(x25519.X25519PrivateKey.generate()._raw_private_bytes(), byteorder='big')
        self.b = int.from_bytes(x25519.X25519PrivateKey.generate()._raw_private_bytes(), byteorder='big')
        
        #self.a = 0x77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a
        apk = x25519.X25519PrivateKey.from_private_bytes(self.a.to_bytes(32, byteorder='big'))
        apk_pub = apk.public_key()
        self.a_pub = self.X25519(self.processScalar(self.a), 9)
        assert self.a_pub == int.from_bytes(apk_pub._raw_public_bytes(), byteorder='big')

        #self.b = 0x5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb
        bpk = x25519.X25519PrivateKey.from_private_bytes(self.b.to_bytes(32, byteorder='big'))
        bpk_pub = bpk.public_key()
        self.b_pub = self.X25519(self.processScalar(self.b), 9)
        assert self.b_pub == int.from_bytes(bpk_pub._raw_public_bytes(), byteorder='big')

        self.a_shared = self.X25519(self.processScalar(self.a), self.processUCoord(self.b_pub))
        self.b_shared = self.X25519(self.processScalar(self.b), self.processUCoord(self.a_pub))
        assert self.a_shared == self.b_shared

    
    def egcd(self, a, b):
        if a == 0:
            return (b, 0, 1)
        else:
            g, y, x = self.egcd(b % a, a)
            return (g, x - (b // a) * y, y)


    def modinv(self, a, m):
        g, x, y = self.egcd(a, m)
        if g != 1:
            raise Exception('modular inverse does not exist')
        else:
            return x % m


    def mask(self, swap):
        mask = 0 - swap
        return mask


    def cswap(self, swap, x_2, x_3):
        dummy = self.mask(swap) & (x_2 ^ x_3)
        x_2 = x_2 ^ dummy
        x_3 = x_3 ^ dummy
        return x_2, x_3


    def bigToLittleEndian(self, num):
        hex_str = hex(num)[2:].zfill(64)

        big_endian_bytes = bytes.fromhex(hex_str)
        little_endian_bytes = big_endian_bytes[::-1]
        little_endian_hex_str = little_endian_bytes.hex()

        return int(little_endian_hex_str, 16)


    def clampScalar(self, scalar):
        bits = bin(scalar)[2:].zfill(256)
        bits = '01' + bits[2:253] + '000'
        return int(bits, 2)


    def clampUCoord(self, u):
        bits = bin(u)[2:].zfill(256)
        bits = '0' + bits[1:]
        return int(bits, 2)

    def processScalar(self, k):
        k_ret = self.bigToLittleEndian(k)
        return self.clampScalar(k_ret)
    
    def processUCoord(self, u):
        u_ret = self.bigToLittleEndian(u)
        return self.clampUCoord(u_ret)

    def X25519(self, k, u):
        bits = self.bits
        p = self.p
        a24 = self.a24
        a48 = self.a48
        x_1 = u
        x_2 = 1
        z_2 = 0
        x_3 = u
        z_3 = 1
        swap = 0
        for t in range(bits - 1, -1, -1):
            k_t = (k >> t) & 1
            swap = swap ^ k_t
            (x_2, x_3) = self.cswap(swap, x_2, x_3)
            (z_2, z_3) = self.cswap(swap, z_2, z_3)
            swap = k_t
            ############stage_1#################mul
            XX = (x_2 * x_2) % p
            ZZ = (z_2 * z_2) % p
            XZ = (z_2 * x_2) % p
            XX1 = (x_2 * x_3) % p
            ZZ1 = (z_2 * z_3) % p
            XZ3 = (x_2 * z_3) % p
            XZ4 = (z_2 * x_3) % p
            #################################### 
            ############stage_2#################add
            S2_1 = (XX - ZZ) % p
            S2_2 = (XX + ZZ) % p
            S2_3 = (XX1 - ZZ1) % p
            S2_4 = (XZ3 - XZ4) % p
            ####################################
            ############stage_3#################mul
            S3_1 = (4 * XZ) % p
            S3_2 = (S2_1 ** 2) % p
            S3_3 = (a48 * XZ) % p
            S3_4 = (S2_3 ** 2) % p
            S3_5 = (S2_4 ** 2) % p
            ####################################
            ############stage_4#################add
            S4_1 = (S2_2 + S3_3) % p
            ####################################
            ############stage_5#################mul
            x_2 = S3_2
            z_2 = (S3_1 * S4_1) % p
            x_3 = S3_4
            z_3 = (x_1 * S3_5) % p


        (x_2, x_3) = self.cswap(swap, x_2, x_3)
        (z_2, z_3) = self.cswap(swap, z_2, z_3)

        return self.bigToLittleEndian((x_2 * self.modinv(z_2, p)) % p)
    
    def clamp(self, n):
        n &= ~7
        n &= ~(128 << 8 * 31)
        n |= 64 << 8 * 31
        return n


for i in range(10000):
    print("Test iteration ", str(i+1))
    inst = ECDH_key_generator()

    print (f"\n\nAlice private (a): \t{hex(inst.a)}")
    print (f"Bob private (b):\t{hex(inst.b)}")

    print ("\n\nAlice public (aG):\t",hex(inst.a_pub))
    print ("Bob public (bG):\t",hex(inst.b_pub))

    print ("\n\nAlice shared (a)bG:\t",hex(inst.a_shared))
    print ("Bob shared (b)aG:\t",hex(inst.b_shared))
    print ("\n\n TEST PASSED\n\n")
