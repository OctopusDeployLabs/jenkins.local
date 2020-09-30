if id "jenkins" >/dev/null 2>&1; then
    echo "User jenkins exists."
else
    echo "Create user jenkins."
    useradd -M -s /bin/bash -u 1001 -g 0 jenkins
fi
