import 'dotenv/config';

const TOKEN_URL = 'https://accounts.spotify.com/api/token';
const API_BASE = 'https://api.spotify.com/v1';

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

async function spotifyRequest<T>(path: string): Promise<T> {
    const token = await getAppToken();
    const response = await fetch(`${API_BASE}${path}`, {
        headers: { Authorization: `Bearer ${token}` },
    });

    if (response.status === 429) {
        const retryAfter = Number(response.headers.get('Retry-After') ?? '1');
        await new Promise((resolve) => setTimeout(resolve, retryAfter * 1000));
        return spotifyRequest<T>(path);
    }

    if (!response.ok) {
        throw new Error(`Spotify API error: ${response.status}`);
    }

    return (await response.json()) as T;
}
