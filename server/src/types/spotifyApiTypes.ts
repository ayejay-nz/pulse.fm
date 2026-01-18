export type SpotifyAlbumTypes = 'album' | 'single' | 'compilation';

export interface SpotifyImageObject {
    url: string;
    height: number | null;
    width: number | null;
}

export interface SpotifyExternalUrls {
    spotify: string;
}

export interface SpotifySimplifiedArtistObject {
    externalUrls: SpotifyExternalUrls;
    href: string;
    id: string;
    name: string;
    type: 'artist';
    uri: string;
}

export interface SpotifySimplifiedTrackObject {
    artists: SpotifySimplifiedArtistObject[];
    availableMarkets: string[];
    discNumber: number;
    durationMs: number;
    explicit: boolean;
    externalUrls: SpotifyExternalUrls;
    href: string;
    id: string;
    isPlayable: boolean;
    linkedFrom: {
        externalUrls: SpotifyExternalUrls;
        href: string;
        id: string;
        type: 'track';
        uri: string;
    };
    restrictions: {
        reason: string;
    };
    name: string;
    previewUrl: string | null;
    trackNumber: number;
    type: 'track';
    uri: string;
    isLocal: boolean;
}

export interface SpotifyCopyrightObject {
    text: string;
    type: string;
}

export interface SpotifyAlbumPartial {
    albumType: SpotifyAlbumTypes;
    totalTracks: number;
    availableMarkets: string[];
    externalUrls: SpotifyExternalUrls;
    href: string;
    id: string;
    images: SpotifyImageObject[];
    name: string;
    releaseDate: string;
    releaseDatePrecision: string;
    restrictions: {
        reason: string;
    };
    type: 'album';
    uri: string;
    artists: SpotifySimplifiedArtistObject[];
}

export interface SpotifyAlbum extends SpotifyAlbumPartial {
    tracks: {
        href: string;
        limit: number;
        next: string | null;
        offset: number;
        previous: string | null;
        items: SpotifySimplifiedTrackObject[];
    };
    copyrights: SpotifyCopyrightObject[];
    externalIds: {
        isrc: string;
        ean: string;
        upc: string;
    };
    genres: string[];
    label: string;
    popularity: number;
}

export interface SpotifyTrack {
    album: SpotifyAlbumPartial;
    artists: SpotifySimplifiedArtistObject[];
    availableMarkets: string[];
    discNumber: number;
    durationMs: number;
    explicit: boolean;
    externalIds: {
        isrc: string;
        ean: string;
        upc: string;
    };
    externalUrls: {
        spotify: string;
    };
    href: string;
    id: string;
    isPlayable: boolean;
    linkedFrom: object;
    restrictions: {
        reason: string;
    };
    name: string;
    popularity: number;
    previewUrl: string | null;
    trackNumber: number;
    type: 'track';
    uri: string;
    isLocal: boolean;
}

export interface SpotifyArtist {
    externalUrls: {
        spotify: string;
    };
    followers: {
        href: string | null;
        total: number;
    };
    genres: string[];
    href: string;
    id: string;
    images: SpotifyImageObject[];
    name: string;
    popularity: number;
    type: 'artist';
    uri: string;
}
