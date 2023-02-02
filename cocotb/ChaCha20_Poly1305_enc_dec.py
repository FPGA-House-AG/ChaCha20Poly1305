from Crypto.Cipher import ChaCha20
from Crypto.Cipher import AES, ChaCha20_Poly1305
from Crypto.Hash import Poly1305
from Crypto.Util._raw_api import (load_pycryptodome_raw_lib,
                                  VoidPointer, SmartPointer,
                                  create_string_buffer,
                                  get_raw_buffer, c_size_t,
                                  c_uint8_ptr)
import sys
import binascii

def our_encryptor(key, counter, plain_text, auth_text):
    cipher = ChaCha20_Poly1305.new(key = key, nonce = counter)
    cipher.update(auth_text)
    r, s, nonce = ChaCha20._derive_Poly1305_key_pair(key, counter)
    newmac = Poly1305.Poly1305_MAC(r, s, plain_text)
    print(r.hex(' '))
    print(s.hex(' '))
    print(nonce.hex(' '))
    #print(newmac.hex(' '))
    cipher_text, digest = cipher.encrypt_and_digest(plain_text)
    return cipher_text, digest

def our_decryptor(key, counter, cipher_text, auth_text):
    cipher = ChaCha20_Poly1305.new(key=key, nonce=counter)
    cipher.update(auth_text)
    return cipher.decrypt_and_verify(cipher_text[:-16], cipher_text[-16:])
'''
key = b'\x80\x81\x82\x83\x84\x85\x86\x87\x88\x89\x8a\x8b\x8c\x8d\x8e\x8f\x90\x91\x92\x93\x94\x95\x96\x97\x98\x99\x9A\x9B\x9C\x9D\x9E\x9F'
#counter = int.from_bytes(b'\x07\x00\x00\x00\x40\x41\x42\x43\x44\x45\x46\x47',"big")
counter = b'\x07\x00\x00\x00\x40\x41\x42\x43\x44\x45\x46\x47'
plain_text = b'\x4c\x61\x64\x69\x65\x73\x20\x61\x6e\x64\x20\x47\x65\x6e\x74\x6c\x65\x6d\x65\x6e\x20\x6f\x66\x20\x74\x68\x65\x20\x63\x6c\x61\x73\x73\x20\x6f\x66\x20\x27\x39\x39\x3a\x20\x49\x66\x20\x49\x20\x63\x6f\x75\x6c\x64\x20\x6f\x66\x66\x65\x72\x20\x79\x6f\x75\x20\x6f\x6e\x6c\x79\x20\x6f\x6e\x65\x20\x74\x69\x70\x20\x66\x6f\x72\x20\x74\x68\x65\x20\x66\x75\x74\x75\x72\x65\x2c\x20\x73\x75\x6e\x73\x63\x72\x65\x65\x6e\x20\x77\x6f\x75\x6c\x64\x20\x62\x65\x20\x69\x74\x2e\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00'
#plain_text = b'\x4c\x61\x64\x69\x65\x73\x20\x61\x6e\x64\x20\x47\x65\x6e\x74\x6c\x65\x6d\x65\x6e\x20\x6f\x66\x20\x74\x68\x65\x20\x63\x6c\x61\x73\x73\x20\x6f\x66\x20\x27\x39\x39\x3a\x20\x49\x66\x20\x49\x20\x63\x6f\x75\x6c\x64\x20\x6f\x66\x66\x65\x72\x20\x79\x6f\x75\x20\x6f\x6e\x6c\x79\x20\x6f\x6e\x65\x20\x74\x69\x70\x20\x66\x6f\x72\x20\x74\x68\x65\x20\x66\x75\x74\x75\x72\x65\x2c\x20\x73\x75\x6e\x73\x63\x72\x65\x65\x6e\x20\x77\x6f\x75\x6c\x64\x20\x62\x65\x20\x69\x74\x2e'
print(len(plain_text))
'''

'''

#aad = b'\x50\x51\x52\x53\xc0\xc1\xc2\xc3\xc4\xc5\xc6\xc7'
aad = b''
#plain_text = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it.".encode('utf-8')
print(f'We are sending the following string \n {plain_text} \nWith the following key \n {str(key)} \nWith the following counter \n {str(counter)} \nWith the following auth text \nb\'\'\n')
retval, digest = our_encryptor(key, counter, plain_text, aad)
listTestByte = (retval + digest).hex(' ')
print("Size of plaintext in bytes "+str(len(plain_text)))
print("Size of cyphertext in bytes "+str(len(retval + digest)))
print(f'We got the result of encrypting as \n {listTestByte} \n')
retval = our_decryptor(key, counter, retval + digest, aad)
print(f'We are sending this cyphered text back to decode with the same parameters and we get the decoded text as \n{retval}\n') 
'''