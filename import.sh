#!/bin/bash
venv/bin/gh2md HaddingtonDynamics/Dexter --login abdullin --idempotent issues.md
rg 'https.*user-images.githubusercontent.com.*(png|jpg|gif)' issues.md --only-matching | xargs wget --directory-prefix=images  --timestamping
