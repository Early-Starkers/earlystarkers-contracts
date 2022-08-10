from merkle_utils import (generate_merkle_proof, generate_merkle_root)

values = [
  100,
  200,
  300,
  400,
  500,
  600,
  700,
  800
]

leaf_index = 1

proof = generate_merkle_proof(values, leaf_index)
root = generate_merkle_root(values)

print("proof", proof)
print("root", root)
print("leaf", 200)
print("false_leaf", 100)


