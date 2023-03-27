# AEAD_encryption_wrapper test
## This readme contains information on the decryptor tests.

We've tested the AEAD_encryption_wrapper.vhd component using automatic tests. These tests are consisted of 6 distinct test cases.

- Generic, "safe" test. This test is the bare minimum needed to test component validity
- Generic, "safe" test with validation using external ChaCha20_Poly1305 encryptor component
- Generic, "safe" test with zero key and zero-nonce test. This test in essence behaves the same as the first two.
- Generic, "safe" test with zero key, zero-nonce and zero (160 * hex(00)) test. 
- Generic, failstate test with wrong inputs to the component. Should stall the component.
- Non-generic, random seed test with arbitrary ammounts of data. Calling this test multiple times assures us component works for different data lengths. 



## Test case 1
This is a generic, "safe" test. Generic because of the plaintext used and safe because we're giving the component currated header_counter parameters and keys. This test should work out of the box.


The plaintext of it is the generic `"Ladies and Gentlemen of the class of \'99: If I could offer you only one tip for the future, sunscreen would be it."` 

The key of this test is the currated 32 bytes of:  `'00 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f '`

The header_counter of this test is the currated 16 bytes of: `'04 00 00 80 00 00 00 01 00 00 00 00 00 00 00 00 '`


## Test case 2
This is a generic, zero-key, "safe" test with validation using external ChaCha20_Poly1305 encryptor component. 
Generic because of the plaintext used and safe because we're giving the component currated header_counter parameters and keys. 
The test results are validated using our own custom ChaCha20_Poly1305 encryptor.


The plaintext of it is the generic `"Ladies and Gentlemen of the class of \'99: If I could offer you only one tip for the future, sunscreen would be it."` 

The key of this test is the currated 32 bytes of:  `'00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 '`

The header_counter of this test is the currated 16 bytes of:  `'04 00 00 80 00 00 00 01 40 41 42 43 44 45 46 47 '`


## Test case 3
This is a generic, "safe" test with validation using external ChaCha20_Poly1305 encryptor component with zero key and custom header_counter. 
Generic because of the plaintext used and safe because we're giving the component currated header_counter parameters and keys. 


The plaintext of it is the generic `\x00 * 128` 

The key of this test is the currated 32 bytes of:  `'00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00  '`

The header_counter of this test is the currated 16 bytes of:  `'04 00 00 80 00 00 00 01 00 00 00 00 00 00 00 00 '`



## Test case 4
Generic, failstate test with wrong inputs to the component. Should stall the component.
Generic because of the plaintext used and safe because we're giving the component currated header_counter parameters and keys. This test should fail.


The plaintext of it is empty `''` 

The key of this test is also empty  `''`

So is the header_counter `''`


## Test case 5
Non-generic, random seed test with arbitrary ammounts of data. Calling this test multiple times assures us component works for different data lengths.  
The plaintext used is generated using a random seed.
The test is safe because we're giving the component currated header_counter parameters and keys.
This test should always pass, regardless of the length of the data sent to it 


The plaintext of it is the generic `DEPENDS OF THE RANDOM SEED` 

The header_counter `DEPENDS OF THE RANDOM SEED` 

The key of this test is the currated 32 bytes of:  `'00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 '`



## Test case 6
Non-generic, random seed test with arbitrary ammounts of data, arbitrary key, header, and data. 
Calling this test multiple times assures us component works for different data lengths and different data as well.  
The plaintext used is generated using a random seed. So is the key, header, etc.
The test is safe because we're giving the component currated header_counter parameters and keys.
This test should always pass, regardless of the length of the data sent to it 


The plaintext of it is the generic `DEPENDS OF THE RANDOM SEED` 

The header_counter `DEPENDS OF THE RANDOM SEED` 

The key of this test is the currated 32 bytes of:  `DEPENDS OF THE RANDOM SEED`