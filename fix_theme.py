import os
import glob
import re

for filepath in glob.glob('lib/**/*.dart', recursive=True):
    with open(filepath, 'r') as f:
        content = f.read()

    if 'AppTheme.textMain' in content or 'Colors.white' in content:
        if 'AppTheme.textMain' in content:
            content = content.replace('AppTheme.textMain', 'Theme.of(context).colorScheme.onSurface')
        
        # Some basic un-consting
        content = re.sub(r'const\s+TextStyle\(', r'TextStyle(', content)
        content = re.sub(r'const\s+Icon\(', r'Icon(', content)
        content = re.sub(r'const\s+Divider\(', r'Divider(', content)
        content = re.sub(r'const\s+BoxDecoration\(', r'BoxDecoration(', content)
        content = re.sub(r'const\s+BorderSide\(', r'BorderSide(', content)
        content = re.sub(r'const\s+Border\.all\(', r'Border.all(', content)
        content = re.sub(r'const\s+Expanded\(', r'Expanded(', content)
        content = re.sub(r'const\s+\[', r'[', content)
        content = re.sub(r'const\s+EdgeInsets', r'EdgeInsets', content)
        content = re.sub(r'const\s+SizedBox', r'SizedBox', content)

        with open(filepath, 'w') as f:
            f.write(content)
