import requests
headers = {'User-Agent': 'Roblox/WinInet'}
response = requests.get('https://vss.pandadevelopment.net/virtual/file/4dad9c7076914682', headers=headers)
print(response.text)