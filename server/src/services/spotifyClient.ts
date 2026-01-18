import 'dotenv/config';

const TOKEN_URL = 'https://accounts.spotify.com/api/token';

let cachedToken: { token: string; expiresAt: number } | null = null;

type AuthData = {
    access_token: string;
    token_type: string;
    expires_in: number;
};

function isAuthData(data: unknown): data is AuthData {
    if (typeof data !== 'object' || data === null) {
        return false;
    }

    return (
        'access_token' in data &&
        typeof (data as AuthData).access_token === 'string' &&
        'token_type' in data &&
        typeof (data as AuthData).token_type === 'string' &&
        'expires_in' in data &&
        typeof (data as AuthData).expires_in === 'number'
    );
}

async function getAppToken() {
    if (cachedToken && cachedToken.expiresAt > Date.now()) {
        return cachedToken;
    }

    const auth = Buffer.from(
        `${process.env.SPOTIFY_CLIENT_ID}:${process.env.SPOTIFY_CLIENT_SECRET}`,
    ).toString('base64');

    const res = await fetch(TOKEN_URL, {
        method: 'POST',
        headers: {
            Authorization: `Basic ${auth}`,
            'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
            grant_type: 'client_credentials',
        }),
    });

    if (!res.ok) throw new Error(`Spotify auth failed: ${res.status}`);
    const data = await res.json();
    if (!isAuthData(data)) throw new Error('Error with Spotify authentication. Please try again');

    cachedToken = {
        token: data.access_token,
        expiresAt: Date.now() + (data.expires_in - 60) * 1000,
    };

    return cachedToken.token;
}

console.log(await getAppToken());
