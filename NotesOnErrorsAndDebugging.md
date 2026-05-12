When you run tests and you get an error which says 
the generated proof length does not match the proof length expected by 
the verifier. check the following: 
1. Make sure you re-generate the verifier after making any changes to the circuit 
2. Make sure the versions of @aztec/bb.js, @aztec/foundation.js  and noir-lang match the versions installed on the computer