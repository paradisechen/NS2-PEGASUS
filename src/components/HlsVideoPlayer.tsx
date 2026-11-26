/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import { useEffect, useRef, useState } from 'react';
import Hls from 'hls.js';
import { FastForward, Pause, Play, Rewind, SkipBack, SkipForward, Volume2, VolumeX } from 'lucide-react';

interface HlsVideoPlayerProps {
  src: string;
  kind?: 'hls' | 'mp4';
  muted?: boolean;
  controls?: boolean;
  autoPlay?: boolean;
  loop?: boolean;
  playsInline?: boolean;
  fadeInOnReady?: boolean;
  poster?: string;
  className?: string;
  style?: React.CSSProperties;
  showControlsOverlay?: boolean;
  nintendoLowerThird?: boolean;
  aspectMode?: number;
  onCycleAspect?: () => void;
  onPrevVideo?: () => void;
  onNextVideo?: () => void;
  onEnded?: () => void;
  'data-testid'?: string;
  onReady?: () => void;
  onError?: () => void;
}

export function HlsVideoPlayer({
  src,
  kind = 'hls',
  muted = true,
  controls = false,
  autoPlay = true,
  loop = true,
  playsInline = true,
  fadeInOnReady = false,
  poster,
  className = '',
  style,
  showControlsOverlay = false,
  nintendoLowerThird = false,
  aspectMode = 0,
  onCycleAspect,
  onPrevVideo,
  onNextVideo,
  onEnded,
  'data-testid': testId,
  onReady,
  onError,
}: HlsVideoPlayerProps) {
  const videoRef = useRef<HTMLVideoElement | null>(null);
  const userPausedRef = useRef(false);
  const scrubTimerRef = useRef<number | null>(null);
  const [ready, setReady] = useState(false);
  const [isPlaying, setIsPlaying] = useState(autoPlay);
  const [isMuted, setIsMuted] = useState(muted);
  const [currentTime, setCurrentTime] = useState(0);
  const [duration, setDuration] = useState(0);
  const [scrubbingDir, setScrubbingDir] = useState<-1 | 0 | 1>(0);

  useEffect(() => {
    const videoEl = videoRef.current;
    if (!videoEl || !src) return;
    setReady(false);
    userPausedRef.current = false;

    const isHls = kind === 'hls' || /\.m3u8(\?|$)/i.test(src) || src.includes('/api/video/hls') || src.includes('/api/lamovie/hls');

    if (!isHls) {
      videoEl.src = src;
      if (autoPlay) {
        videoEl.play().then(() => setIsPlaying(true)).catch(() => setIsPlaying(false));
      }
      return;
    }

    if (Hls.isSupported()) {
      const hls = new Hls({
        enableWorker: true,
        lowLatencyMode: false,
        startLevel: 0,
        capLevelToPlayerSize: true,
        maxBufferLength: 14,
      });
      hls.loadSource(src);
      hls.attachMedia(videoEl);
      hls.on(Hls.Events.MANIFEST_PARSED, () => {
        if (autoPlay && !userPausedRef.current) {
          videoEl.play().then(() => setIsPlaying(true)).catch(() => setIsPlaying(false));
        }
      });
      hls.on(Hls.Events.ERROR, (_ev, data) => {
        if (data.fatal) {
          hls.destroy();
          onError?.();
        }
      });
      return () => {
        hls.destroy();
      };
    }

    if (videoEl.canPlayType('application/vnd.apple.mpegurl')) {
      videoEl.src = src;
      if (autoPlay) {
        videoEl.play().then(() => setIsPlaying(true)).catch(() => setIsPlaying(false));
      }
      return;
    }

    onError?.();
  }, [autoPlay, kind, onError, src]);

  useEffect(() => {
    if (videoRef.current) {
      videoRef.current.muted = isMuted;
    }
  }, [isMuted]);

  useEffect(() => {
    return () => {
      if (scrubTimerRef.current) window.clearInterval(scrubTimerRef.current);
    };
  }, []);

  const togglePlay = () => {
    const v = videoRef.current;
    if (!v) return;
    if (v.paused) {
      userPausedRef.current = false;
      v.play().then(() => setIsPlaying(true)).catch(() => {});
    } else {
      userPausedRef.current = true;
      v.pause();
      setIsPlaying(false);
    }
  };

  const seekFluidly = (nextTimeSec: number) => {
    const v = videoRef.current;
    if (!v) return;
    const maxD = Number.isFinite(v.duration) && v.duration > 0 ? v.duration : 9999;
    const clamped = Math.max(0, Math.min(maxD - 0.15, nextTimeSec));
    v.currentTime = clamped;
    setCurrentTime(clamped);
    // Keep going fluidly while scrubbing unless explicitly paused
    if (!userPausedRef.current && v.paused) {
      v.play().then(() => setIsPlaying(true)).catch(() => {});
    }
  };

  const startHoldScrub = (dir: -1 | 1) => {
    if (scrubTimerRef.current) window.clearInterval(scrubTimerRef.current);
    setScrubbingDir(dir);
    if (videoRef.current) {
      seekFluidly(videoRef.current.currentTime + dir * 2);
    }
    scrubTimerRef.current = window.setInterval(() => {
      if (videoRef.current) {
        seekFluidly(videoRef.current.currentTime + dir * 3);
      }
    }, 90);
  };

  const stopHoldScrub = () => {
    setScrubbingDir(0);
    if (scrubTimerRef.current) {
      window.clearInterval(scrubTimerRef.current);
      scrubTimerRef.current = null;
    }
  };

  const formatTime = (secs: number) => {
    if (Number.isNaN(secs) || secs <= 0) return '0:00';
    const m = Math.floor(secs / 60);
    const s = Math.floor(secs % 60);
    return `${m}:${s.toString().padStart(2, '0')}`;
  };

  const computedStyle = fadeInOnReady
    ? {
        ...style,
        opacity: ready ? style?.opacity ?? 1 : 0,
      }
    : style;

  return (
    <div className="relative w-full h-full group flex items-center justify-center">
      <video
        ref={videoRef}
        data-testid={testId}
        muted={isMuted}
        controls={controls && !showControlsOverlay && !nintendoLowerThird}
        autoPlay={autoPlay}
        loop={loop}
        playsInline={playsInline}
        poster={poster}
        preload="auto"
        onTimeUpdate={() => {
          if (videoRef.current) setCurrentTime(videoRef.current.currentTime);
        }}
        onDurationChange={() => {
          if (videoRef.current && Number.isFinite(videoRef.current.duration)) {
            setDuration(videoRef.current.duration);
          }
        }}
        onPlaying={() => {
          setReady(true);
          setIsPlaying(true);
          onReady?.();
        }}
        onCanPlay={() => {
          setReady(true);
          if (autoPlay && !userPausedRef.current && videoRef.current?.paused) {
            videoRef.current.play().then(() => setIsPlaying(true)).catch(() => {});
          }
          onReady?.();
        }}
        onPause={() => {
          if (userPausedRef.current) setIsPlaying(false);
        }}
        onEnded={() => onEnded?.()}
        onError={() => onError?.()}
        className={className}
        style={computedStyle}
      />

      {nintendoLowerThird && (
        <div
          data-testid="nintendo-lower-third-player"
          className="absolute inset-x-0 bottom-0 z-30 bg-[#08090D]/95 border-t border-white/15 px-6 pt-3.5 pb-4 flex flex-col gap-3"
        >
          {/* Fluid Timeline Scrubber (does not pause when scrubbing) */}
          <div className="flex items-center gap-3">
            <span className="text-xs font-ud-bold tabular-nums text-white w-12">
              {formatTime(currentTime)}
            </span>
            <input
              type="range"
              min={0}
              max={duration || 100}
              step={0.1}
              value={currentTime}
              onChange={(e) => seekFluidly(Number(e.target.value))}
              className="flex-1 h-2.5 bg-white/25 rounded-full appearance-none cursor-pointer accent-[#E60012]"
            />
            <span className="text-xs font-ud-bold tabular-nums text-white/60 w-12 text-right">
              {formatTime(duration)}
            </span>
          </div>

          {/* Way Bigger Flat Nintendo Black Media Buttons */}
          <div className="relative flex items-center justify-center gap-3.5">
            {onPrevVideo && (
              <button
                type="button"
                data-testid="player-prev-video"
                onClick={onPrevVideo}
                className="w-16 h-12 rounded-xl bg-[#15171E] hover:bg-[#232734] border-2 border-white/25 text-white flex items-center justify-center cursor-pointer active:scale-95 transition"
                aria-label="Previous video"
              >
                <SkipBack className="w-5 h-5 fill-current" />
              </button>
            )}

            <button
              type="button"
              onMouseDown={() => startHoldScrub(-1)}
              onMouseUp={stopHoldScrub}
              onMouseLeave={stopHoldScrub}
              onTouchStart={() => startHoldScrub(-1)}
              onTouchEnd={stopHoldScrub}
              onClick={() => videoRef.current && seekFluidly(videoRef.current.currentTime - 8)}
              className={`w-18 h-12 rounded-xl border-2 text-white flex items-center justify-center cursor-pointer active:scale-95 transition ${
                scrubbingDir < 0 ? 'bg-[#2A2E3B] border-white' : 'bg-[#15171E] hover:bg-[#232734] border-white/25'
              }`}
              aria-label="Rewind"
            >
              <Rewind className="w-5 h-5 fill-current" />
            </button>

            <button
              type="button"
              data-testid="player-play-pause"
              onClick={togglePlay}
              className="w-24 h-14 rounded-2xl bg-[#111216] hover:bg-[#1E212B] border-2 border-white text-white flex items-center justify-center cursor-pointer active:scale-95 transition"
              aria-label={isPlaying ? 'Pause' : 'Play'}
            >
              {isPlaying ? <Pause className="w-6 h-6 fill-current" /> : <Play className="w-6 h-6 fill-current" />}
            </button>

            <button
              type="button"
              onMouseDown={() => startHoldScrub(1)}
              onMouseUp={stopHoldScrub}
              onMouseLeave={stopHoldScrub}
              onTouchStart={() => startHoldScrub(1)}
              onTouchEnd={stopHoldScrub}
              onClick={() => videoRef.current && seekFluidly(videoRef.current.currentTime + 8)}
              className={`w-18 h-12 rounded-xl border-2 text-white flex items-center justify-center cursor-pointer active:scale-95 transition ${
                scrubbingDir > 0 ? 'bg-[#2A2E3B] border-white' : 'bg-[#15171E] hover:bg-[#232734] border-white/25'
              }`}
              aria-label="Fast Forward"
            >
              <FastForward className="w-5 h-5 fill-current" />
            </button>

            {onNextVideo && (
              <button
                type="button"
                data-testid="player-next-video"
                onClick={onNextVideo}
                className="w-16 h-12 rounded-xl bg-[#15171E] hover:bg-[#232734] border-2 border-white/25 text-white flex items-center justify-center cursor-pointer active:scale-95 transition"
                aria-label="Next video"
              >
                <SkipForward className="w-5 h-5 fill-current" />
              </button>
            )}

            <div className="absolute right-0 flex items-center gap-2">
              {onCycleAspect && (
                <button
                  type="button"
                  onClick={onCycleAspect}
                  className="w-14 h-12 rounded-xl bg-[#15171E] hover:bg-[#232734] border-2 border-white/25 text-white flex items-center justify-center cursor-pointer"
                  aria-label="Aspect Ratio"
                >
                  <span
                    className={`block border-2 border-white rounded-sm ${
                      aspectMode === 2
                        ? 'w-4 h-4'
                        : aspectMode === 1
                          ? 'w-6 h-3.5'
                          : aspectMode === 3
                            ? 'w-6 h-4 bg-white/40'
                            : 'w-5 h-3.5'
                    }`}
                  />
                </button>
              )}
              <button
                type="button"
                onClick={() => setIsMuted((m) => !m)}
                className="w-14 h-12 rounded-xl bg-[#15171E] hover:bg-[#232734] border-2 border-white/25 text-white flex items-center justify-center cursor-pointer"
                aria-label={isMuted ? 'Unmute' : 'Mute'}
              >
                {isMuted ? <VolumeX className="w-5 h-5" /> : <Volume2 className="w-5 h-5" />}
              </button>
            </div>
          </div>
        </div>
      )}

      {showControlsOverlay && !nintendoLowerThird && (
        <div className="absolute inset-x-0 bottom-0 z-20 flex items-center gap-3 px-4 py-3 bg-gradient-to-t from-black/90 via-black/50 to-transparent opacity-90 group-hover:opacity-100 transition-opacity">
          <button
            type="button"
            onClick={togglePlay}
            className="p-2 rounded-full bg-white/20 hover:bg-white/30 text-white cursor-pointer"
            aria-label={isPlaying ? 'Pause' : 'Play'}
          >
            {isPlaying ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4 fill-current" />}
          </button>

          <span className="text-xs font-mono-tabular text-white shrink-0">
            {formatTime(currentTime)} / {formatTime(duration)}
          </span>

          <input
            type="range"
            min={0}
            max={duration || 100}
            value={currentTime}
            onChange={(e) => seekFluidly(Number(e.target.value))}
            className="flex-1 h-1.5 bg-white/30 rounded-lg appearance-none cursor-pointer accent-[#E50914]"
          />

          <button
            type="button"
            onClick={() => setIsMuted((m) => !m)}
            className="p-2 rounded-full bg-white/20 hover:bg-white/30 text-white cursor-pointer"
            aria-label={isMuted ? 'Unmute' : 'Mute'}
          >
            {isMuted ? <VolumeX className="w-4 h-4" /> : <Volume2 className="w-4 h-4" />}
          </button>
        </div>
      )}
    </div>
  );
}
