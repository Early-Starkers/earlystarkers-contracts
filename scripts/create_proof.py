from merkle_utils import (
  generate_merkle_proof, 
  generate_merkle_root, 
  verify_merkle_proof
)

with open("address_list.txt", "r") as f:
  addresses = f.readlines()

  addr_felts = []
  for addr in addresses:
    addr_felts.append(int(addr))

  leaf_idx = 68
  proof = generate_merkle_proof(addr_felts, leaf_idx)
  root = generate_merkle_root(addr_felts)
  proof_str = []

  print(proof)
  print(root)
  print(addresses[leaf_idx])

  x = []
  for _p in proof:
    x.append(_p)
  x.append(root)

  print(verify_merkle_proof(addr_felts[leaf_idx], x))
  print(verify_merkle_proof(addr_felts[leaf_idx+1], proof))
  print(verify_merkle_proof(addr_felts[leaf_idx-1], proof))

  with open("proof.json", "w+") as f:
    f.write("{\n")
    f.write(f"\t\"proof\": [") 
    for i in range(len(proof)):
      p = proof[i]
      if i == len(proof) - 1:
        f.write(f"\"{p}\"")
      else:
        f.write(f"\"{p}\", ")
    f.write("],\n")
      
    f.write(f"\t\"root\": \"{root}\",\n")
    f.write(f"\t\"leaf\": \"{addr_felts[leaf_idx]}\",\n")
    f.write(f"\t\"false_leaf\": \"{addr_felts[leaf_idx+1]}\"\n")
    f.write("}\n")

print(verify_merkle_proof(
  1548212038515435049434649461909105053054826076624110814896542634387770982281, 
  [
  647596409664803518066474254733364395705059147350, 
  598230191716302885685149790442664849260069733117879728614939641362008457815, 
  2417532160093105280204308488180786743299471986402108975790735410060141686562, 
  3131090467424426290698681972419312142046514328805055551679640873538745353169, 
  388516573469246821185437020458440858678811541435640622521848067515297370181, 
  1230644064886764924872086391992767837585444042135655876650191597698069713669, 
  2631237161875795544551026431366850092660852464321515776970454740150407354641, 
  939372635011896157343567173681343256161088044487733515582119066584079592766
  ] 
))
  