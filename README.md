# ipset
Blocked ip for ipset


wget -qO- https://raw.githubusercontent.com/Akademik120706/ipset/main/update-ipset.sh | bash

dodavanje crona 2 puta sedmicno (auto update ip list)

(crontab -l 2>/dev/null; echo "0 3 * * 1,4 wget -qO- https://raw.githubusercontent.com/Akademik120706/ipset/main/update-ipset.sh | bash") | crontab -

