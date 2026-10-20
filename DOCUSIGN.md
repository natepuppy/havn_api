# DocuSign

Havn sends the Rep Agreement to every rep, plus one addendum chosen by level. Other onboarding documents still go out by email.

The integration key is live on the company production account. Havn signs in with a JWT grant. The private key stays in `havn_api/.env` and is not written here.

Production login and all four templates were verified against `https://na2.docusign.net`. The API Account ID ends in `7296`. An earlier copy ended in `729e` and DocuSign rejected it.

## Accounts

| Account | Login | Site | Use |
| --- | --- | --- | --- |
| Developer | `nathan.clark.dev@gmail.com` | https://account-d.docusign.com | Created the integration key. Personal Gmail cannot finish Go-Live. |
| Company | `Dallas.junior@gmail.com` | https://account.docusign.com | Production account **Dallas Junior - 25839684**. Owns the templates. Plan is Business Pro. |
| Admin | `admin@havnpestcontrol.com` | Both sites | Company-domain admin on the developer account and the company account. This is the login that promotes the key and grants consent. |

## Production app

| Setting | Value |
| --- | --- |
| App | Havn Pest Control |
| Integration key | `b709ceee-00bc-454d-9db9-cc43e4d2a80a` |
| Go-Live status | App is live |
| User ID | `c4fe5924-5e6d-48fd-976a-5b5d83fee9a4` |
| API Account ID | `290efa71-b491-49ae-82d5-0c056ce37296` |
| Account base URI | `https://na2.docusign.net` |
| OAuth host | `https://account.docusign.com` |

Those values are in `havn_api/.env` as `DOCUSIGN_INTEGRATION_KEY`, `DOCUSIGN_USER_ID`, `DOCUSIGN_ACCOUNT_ID`, `DOCUSIGN_OAUTH_HOST`, and `DOCUSIGN_REST_HOST`.

Go-Live does not copy the redirect URI or the RSA public key. On the production app, add both before consent:

- Redirect URI: `https://localhost`
- This public key, which matches `DOCUSIGN_RSA_PRIVATE_KEY`:

Keypair ID: `35975be6-bfdc-4f8a-b6ec-b7527228c404`

```
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlhMwwszdg0pFAnQ9pRI4
7yMkuhKNZKOEesBVz0maJYI1jOU3vETucXqNzc5ezxMPOpEXyd6y4FXYC3MGyiZA
dcC2qxUOT17rqwf3LyfAwuZ4pnVS8y/cX/PkUu95QdX5+yz/aaPh/9v1qVWMQX4p
L79DJsf3NaAbZHsOFusnJ9odgtcCe/aKn30Fa9zhTJyVwas9EgCVj1pB0pZWDnVO
VTZn0c3/XYJmz83HSl11c15AKDS7ynadchmq1G59bs7/Rdp5Xgx1u9oo8FJEk1z1
u5fsAem5a9S971phzQ4hn1a2Is8YJTvRGtSFJnuSDibORkXin9f8ch9OXLcv7KtW
cwIDAQAB
-----END PUBLIC KEY-----
```

Consent is already granted for User ID `c4fe5924-5e6d-48fd-976a-5b5d83fee9a4`, which is `admin@havnpestcontrol.com` on the company account. Consent from `Dallas.junior@gmail.com` does not cover that user. To grant it again, sign in as `admin@havnpestcontrol.com` and open:

https://account.docusign.com/oauth/auth?response_type=code&scope=signature%20impersonation&client_id=b709ceee-00bc-454d-9db9-cc43e4d2a80a&redirect_uri=https://localhost

A failed `https://localhost` page after **Allow** is expected.

## Templates

Templates live in the company account. Each Havn document stores its template ID.

| Havn document | Who receives it | Template ID |
| --- | --- | --- |
| Rep Agreement | Every rep | `736474c4-34c8-4f48-a4a3-8727bd55a9ba` |
| Havn Rookie Addendum | Level Rookie | `bf7c1049-dc3c-4270-8f63-b0240473d8a8` |
| Havn Veteran Addendum | Level Veteran | `3809bfb3-d00d-42bc-a829-7894284d0d23` |
| Havn Pro Addendum | Level Pro | `e8048ca0-1a5b-4cf7-bed9-6c5c0349eadb` |

Each template has two roles:

- **Rep**, routing order 1. Havn fills the name and email from the rep.
- **Company**, routing order 2. The company signer’s name and email are saved on the template. Havn does not replace that person.

Addendums are filled by data label: `rep_name`, `rep_email`, `start_date`, `market`, `drivers_license`.

The Rep Agreement is filled by field ID:

| Field | ID | Value |
| --- | --- | --- |
| Rep name | `1ba14f97-f479-4e19-a5f0-8e62b5783954` | Rep full name |
| Rep email | `08b8757a-d757-4392-80f0-2a17900065ac` | Rep email |
| Sales manager | `d580bc98-88d9-4dfa-8551-ec22d02c88a8` | Recruiter full name |

Address, City/State/Zip, and company name `d2433add-7111-4c94-b7a6-cd6daa228c4a` are not filled yet.

## What Havn does

`Reps::SendDocuments` always includes the Rep Agreement and the addendum whose level matches the rep. Those two documents go out as one DocuSign envelope. The agreement is the first document and the addendum is attached after it. The rep and the company signer each sign once. Other onboarding documents are still emailed.

DocuSign posts status changes to `POST /docusign/webhooks`. The app checks `X-DocuSign-Signature-1` with `DOCUSIGN_CONNECT_KEY`. Opening a rep also asks DocuSign for the current envelope status, so a packet both signers have finished shows as **Agreement signed** even when Connect has not posted. Connect is not configured yet.

## Local run

The API container publishes on port **3001** because another app already uses port 3000. Restart the API after changing `.env` so the container reloads it. The desk is http://localhost:5173. Sign in with `admin@example.com` / `pass123!!!`.

```bash
docker compose -f docker-compose.dev.yml up
```

## Test a send

Create one rep at http://localhost:5173/reps/new. Use an inbox you can open, and pick one level. Havn sends one DocuSign envelope: the **Rep Agreement** with that level's addendum attached. Welcome letter and the other documents still arrive by email.

On the rep page, the agreement and the addendum should both move from queued to **sent**. Open the DocuSign email and confirm both documents are in the packet, with the filled fields, then sign as the rep. The company signer on the Rep Agreement is the person saved on the template.

Reload the rep after both the rep and the company signer finish. Havn asks DocuSign for the envelope status and shows **Agreement signed**. DocuSign Connect is not set up, and this machine is not reachable from DocuSign, so the status does not change until the page is loaded.
