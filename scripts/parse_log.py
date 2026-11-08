import sys
path = sys.argv[1]

count = 0
with open(path, encoding="utf-8", errors="replace") as f:           
        for line in f: 
            if line.startswith("Error:"):  # True, because it checks the start of the string
                count += 1
print(f"Found {count} error(s)")