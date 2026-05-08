import os
import glob
import re

for filepath in glob.glob('lib/**/*.dart', recursive=True):
    with open(filepath, 'r') as f:
        content = f.read()

    modified = False
    
    # We look for const Text( ... Theme.of(context) ... )
    # A simple blanket remove of const OutlineInputBorder:
    if 'const OutlineInputBorder' in content:
        content = re.sub(r'const\s+OutlineInputBorder', r'OutlineInputBorder', content)
        modified = True
        
    if 'const Text(' in content and 'Theme.of(context)' in content:
        # A bit risky to remove all const Text, but safe enough to remove 'const ' before 'Text('
        # if 'Theme.of(context)' is nearby. We'll just remove 'const ' before 'Text' globally in this file
        content = re.sub(r'const\s+Text\(', r'Text(', content)
        modified = True
        
    # Also check if I missed any const InputDecoration
    if 'const InputDecoration' in content:
        content = re.sub(r'const\s+InputDecoration', r'InputDecoration', content)
        modified = True

    if modified:
        with open(filepath, 'w') as f:
            f.write(content)
