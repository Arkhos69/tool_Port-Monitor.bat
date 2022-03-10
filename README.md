# Port Monitor

[Port-Monitor.bat](https://github.com/Arkhos69/tool_Port-Monitor.bat/blob/main/tool_Port-Monitor.bat)

This tool can do:

- Sort State type
- Search match Port, PID, IP Address
- Show Port info (ex. :443=https, localhost)
- Count Ports and Show Dynamic stat table
- Check "LISTENING" Port is connect to Foreign Host
- Can be more clearly and Easily to check port.

## Stat Table

- If the peak changes, it will be displayed with a red background.

![peak1](https://user-images.githubusercontent.com/98234168/155694854-5e0a5a92-c17e-43d9-a3d3-8bbb6df4d89a.png)

![peak2](https://user-images.githubusercontent.com/98234168/155696430-dc7d421a-36dd-4e56-b107-22e133079cb6.png)

- When the value goes up or down it will display in red or green.

![up](https://user-images.githubusercontent.com/98234168/155784628-db70c940-df9b-43f5-a282-771649039484.png)

![down](https://user-images.githubusercontent.com/98234168/155784652-4f9ba7b0-44c3-4163-91f4-2e70698d03ea.png)

## Filter and Search

![filter_search_intro](https://user-images.githubusercontent.com/98234168/157106231-cb98e891-b82b-44ba-8ebf-dca83aa7c42a.png)

---
![filter_cmd](https://user-images.githubusercontent.com/98234168/157106251-170344a9-6c92-42ab-bdcf-03faa0c8fb8f.png)

![netstat_search](https://user-images.githubusercontent.com/98234168/157690858-fa956fa6-ab44-4564-9d39-191ea3e7afca.png)

---
![filter_cmd_v6](https://user-images.githubusercontent.com/98234168/157106385-8312c14d-5b65-4db1-a262-af65c3810834.png)

![netstat_search_v6](https://user-images.githubusercontent.com/98234168/157690937-5139d923-6088-4a7b-8096-b959b72115be.png)

## Multiple Monitor

If you wnat to Monitor multiple port at the same time you can try Command: /all

- In this command would diplay all ports.
- You can also use Filter function to check whatever you want and easily.
- If you find a suspicious process you can Press 'N' and type the PID, this would open a new cmd window and start Single Monitor.

![filter1](https://user-images.githubusercontent.com/98234168/153688237-cf9ef4dd-e098-4e81-9398-2baedb2fa819.png)

### After

![newfilter2](https://user-images.githubusercontent.com/98234168/154867314-eb5f8882-7a6d-4154-ab39-581208bc514a.png)

Press 'R' to reload port contents and still apply Filters.

### Before

![newfilter1](https://user-images.githubusercontent.com/98234168/154867326-ac7c826b-a8c8-4722-9a90-85a30afefc5c.png)

## Single Monitor

![tor2](https://user-images.githubusercontent.com/98234168/154866663-e3f5bfcb-73b6-4fac-a4cb-541fa2d03c78.png)

![browser](https://user-images.githubusercontent.com/98234168/154960072-ca7b7e4f-fd91-48cd-90b5-4b5c2ff72856.png)

Reload port contents per 1 second, or Press R.

Press N can open a new cmd window to Monitor another process.

![port_monitor9](https://user-images.githubusercontent.com/98234168/153104892-17529eb1-7ab1-4f0b-a837-be45e942f2ce.png)

Thanks: [mlocati](https://gist.github.com/mlocati) giving us [win10colors.cmd](https://gist.github.com/mlocati/fdabcaeb8071d5c75a2d51712db24011) a very useful and amazing way to turn cmd being colorful.

![parasite-respect](https://user-images.githubusercontent.com/98234168/153065065-9ac7d784-3db8-4379-8d5d-33e52ba45b47.gif)
