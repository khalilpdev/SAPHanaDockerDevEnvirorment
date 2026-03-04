# SAP Business One Installation Media

Place the SAP Business One 10.00.300 FP 2508 Linux installer archive here
before running `docker compose build`.

## How to Download

1. Log in to [SAP Service Marketplace / SAP for Me](https://me.sap.com/) with
   your **S-User** credentials.
2. Navigate to **Software Downloads → Support Packages & Patches**.
3. Search for:  `SAP Business One 10.0 FP2508 for SAP HANA – Linux x86_64`
4. Download the `.tar.gz` archive and rename / place it here:

```
./b1/media/B1_10.0_FP2508_FOR_HANA_LINUX_X86_64.tar.gz
```

> **Note:** The archive is typically several GB in size. This folder is listed
> in `.gitignore` so the binary will never be committed to the repository.
