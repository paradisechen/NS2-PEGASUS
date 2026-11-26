import { useEffect, useRef, useState } from 'react';
import { ChevronLeft, ChevronRight, ImagePlus, Minus, Pencil, Plus, Wallpaper } from 'lucide-react';
import type { AdaptivePalette, GameItem } from '../types/skyline';
import type { Switch2LayoutMetrics } from '../utils/rp5Layout';
import { SwitchPdfIcon } from './SwitchPdfIcons';
import { BottomControllerGlyph } from './BottomControllerGlyph';

const CONSOLE_CHOICES = [
  'Nintendo Switch',
  'Nintendo 3DS',
  'GameCube',
  'Wii',
  'Wii U',
  'Nintendo 64',
  'SNES',
  'NES',
  'Game Boy Advance',
  'PSP',
  'PlayStation 2',
  'Android',
];

interface GameEditOverlayProps {
  isOpen: boolean;
  mode?: 'quick' | 'detail';
  game: GameItem | null;
  palette: AdaptivePalette;
  metrics: Switch2LayoutMetrics;
  onSaveGame: (
    gameId: string,
    updates: {
      title: string;
      coverUrl?: string;
      backgroundUrl?: string;
      platform?: string;
      releaseYear?: string;
    }
  ) => void;
  onClose: () => void;
}

/**
 * Switch 2 overlay matching UserSelectOverlay:
 * - Centered Main Photo (Artwork) & Game Background side-by-side with device upload
 * - Quick mode (+ / Hold on Home/Software): ONLY Game Name + Save below artwork
 * - Detail mode (Game Page -> Edit Info): Adds Nintendo-style Console Type & Year controls below Game Name
 */
export function GameEditOverlay({
  isOpen,
  mode = 'quick',
  game,
  palette,
  metrics,
  onSaveGame,
  onClose,
}: GameEditOverlayProps) {
  const [rendered, setRendered] = useState(isOpen);
  const [visible, setVisible] = useState(false);
  const [draftTitle, setDraftTitle] = useState(game?.title ?? '');
  const [draftCover, setDraftCover] = useState<string | undefined>(undefined);
  const [draftBg, setDraftBg] = useState<string | undefined>(undefined);
  const [draftPlatform, setDraftPlatform] = useState(game?.platform ?? 'Nintendo Switch');
  const [draftYear, setDraftYear] = useState(game?.releaseYear ?? '2024');
  const [editingTitle, setEditingTitle] = useState(false);
  const coverInputRef = useRef<HTMLInputElement>(null);
  const bgInputRef = useRef<HTMLInputElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (isOpen && game) {
      setRendered(true);
      setDraftTitle(game.title);
      setDraftCover(game.coverUrl);
      setDraftBg(game.backgroundUrl || game.coverUrl);
      setDraftPlatform(game.platform || 'Nintendo Switch');
      setDraftYear(game.releaseYear || '2024');
      setEditingTitle(false);
      const raf = requestAnimationFrame(() => {
        requestAnimationFrame(() => setVisible(true));
      });
      return () => cancelAnimationFrame(raf);
    }
    setVisible(false);
    const timer = window.setTimeout(() => setRendered(false), 160);
    return () => window.clearTimeout(timer);
  }, [isOpen, game?.id]);

  useEffect(() => {
    if (!isOpen) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        e.stopPropagation();
        if (editingTitle) setEditingTitle(false);
        else onClose();
      }
    };
    window.addEventListener('keydown', onKey, true);
    return () => window.removeEventListener('keydown', onKey, true);
  }, [isOpen, editingTitle, onClose]);

  if (!rendered || !game) return null;

  const h = metrics.viewportHeight;
  const artSize = Math.max(96, Math.round(h * (mode === 'detail' ? 0.175 : 0.2)));
  const sheetPadX = Math.max(24, Math.round(metrics.screenMargin * 0.95));
  const displayCover = draftCover || game.coverUrl;
  const displayBg = draftBg || game.backgroundUrl || game.coverUrl;

  const compressImageFileToDataUrl = (file: File, maxDim: number): Promise<string> =>
    new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onerror = () => reject(new Error('Read failed'));
      reader.onload = () => {
        const raw = typeof reader.result === 'string' ? reader.result : '';
        if (!raw) return reject(new Error('Empty file'));
        const img = new Image();
        img.onload = () => {
          const scale = Math.min(1, maxDim / Math.max(img.width || 1, img.height || 1));
          const w = Math.max(1, Math.round((img.width || maxDim) * scale));
          const hPx = Math.max(1, Math.round((img.height || maxDim) * scale));
          try {
            const canvas = document.createElement('canvas');
            canvas.width = w;
            canvas.height = hPx;
            const ctx = canvas.getContext('2d');
            if (!ctx) return resolve(raw);
            ctx.drawImage(img, 0, 0, w, hPx);
            resolve(canvas.toDataURL('image/jpeg', 0.84));
          } catch {
            resolve(raw);
          }
        };
        img.onerror = () => resolve(raw);
        img.src = raw;
      };
      reader.readAsDataURL(file);
    });

  const handleCoverUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    compressImageFileToDataUrl(file, 720)
      .then((compressed) => {
        setDraftCover(compressed);
      })
      .catch(() => {});
  };

  const handleBgUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    compressImageFileToDataUrl(file, 1280)
      .then((compressed) => {
        setDraftBg(compressed);
      })
      .catch(() => {});
  };

  const stepPlatform = (dir: -1 | 1) => {
    const idx = CONSOLE_CHOICES.indexOf(draftPlatform);
    const cur = idx >= 0 ? idx : 0;
    const next = (cur + dir + CONSOLE_CHOICES.length) % CONSOLE_CHOICES.length;
    setDraftPlatform(CONSOLE_CHOICES[next]);
  };

  const stepYear = (dir: -1 | 1) => {
    const parsed = parseInt(draftYear, 10);
    const base = !Number.isNaN(parsed) && parsed >= 1970 && parsed <= 2035 ? parsed : 2024;
    const next = Math.max(1972, Math.min(2032, base + dir));
    setDraftYear(String(next));
  };

  const handleCommitSave = () => {
    onSaveGame(game.id, {
      title: draftTitle.trim() || game.title,
      coverUrl: displayCover,
      backgroundUrl: displayBg,
      ...(mode === 'detail'
        ? {
            platform: draftPlatform.trim() || game.platform,
            releaseYear: draftYear.trim() || game.releaseYear,
          }
        : {}),
    });
    onClose();
  };

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label={mode === 'detail' ? 'Edit Info' : 'Edit Game'}
      data-testid="game-edit-overlay"
      data-edit-mode={mode}
      className="absolute inset-0 z-50 flex flex-col justify-end overflow-hidden"
    >
      <div
        onClick={onClose}
        className="absolute inset-0 bg-black/50 transition-all duration-180 ease-out"
        style={{
          opacity: visible ? 1 : 0,
          backdropFilter: visible ? 'blur(8px)' : 'blur(0px)',
          WebkitBackdropFilter: visible ? 'blur(8px)' : 'blur(0px)',
        }}
      />

      <div
        className="relative z-10 w-full flex flex-col justify-between transition-all duration-180"
        style={{
          height: mode === 'detail' ? '68%' : '56%',
          backgroundColor: palette.overlaySheetBg,
          color: palette.overlayText,
          transform: visible ? 'translateY(0%)' : 'translateY(100%)',
          transitionTimingFunction: 'cubic-bezier(0.16, 1, 0.3, 1)',
          borderTop: `1px solid ${palette.overlayDivider}`,
        }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Top Header matching UserSelectOverlay */}
        <div style={{ paddingLeft: `${sheetPadX}px`, paddingRight: `${sheetPadX}px` }}>
          <div
            className="flex items-center justify-between"
            style={{
              paddingTop: `${Math.max(12, Math.round(h * 0.022))}px`,
              paddingBottom: `${Math.max(10, Math.round(h * 0.018))}px`,
            }}
          >
            <h2
              className="font-ud-semibold tracking-tight"
              style={{ fontSize: `${Math.max(16, Math.round(h * 0.032))}px` }}
            >
              {mode === 'detail' ? 'Edit Info' : 'Edit Game'}
            </h2>
          </div>
          <div className="w-full h-px" style={{ backgroundColor: palette.overlayDivider }} />
        </div>

        {/* Centered Artwork + Game Background Side-by-Side + Metadata Below */}
        <div
          className="flex-1 flex flex-col items-center justify-center gap-3.5 min-h-0"
          style={{ paddingLeft: `${sheetPadX}px`, paddingRight: `${sheetPadX}px` }}
        >
          <div className="flex items-center justify-center gap-6">
            {/* Main Photo (Cover) */}
            <div className="flex flex-col items-center">
              <button
                type="button"
                data-testid="game-edit-cover-btn"
                onClick={() => coverInputRef.current?.click()}
                aria-label="Upload main photo from device"
                className="relative overflow-hidden cursor-pointer focus:outline-none transition-transform duration-150 hover:scale-[1.03]"
                style={{
                  width: `${artSize}px`,
                  height: `${artSize}px`,
                  borderRadius: '10px',
                  border: `3px solid ${palette.borderPrimary}`,
                  backgroundColor: palette.overlayCardBg,
                }}
              >
                <img
                  src={displayCover}
                  alt={draftTitle || game.title}
                  referrerPolicy="no-referrer"
                  className="w-full h-full object-cover block"
                />
                <span className="absolute inset-x-0 bottom-0 py-1 px-2 bg-black/75 text-white flex items-center justify-center gap-1 text-[10px] font-ud-semibold">
                  <ImagePlus className="w-3 h-3" />
                  <span>Main Photo</span>
                </span>
              </button>
              <input
                ref={coverInputRef}
                type="file"
                accept="image/*"
                onChange={handleCoverUpload}
                className="hidden"
              />
            </div>

            {/* Game Background */}
            <div className="flex flex-col items-center">
              <button
                type="button"
                data-testid="game-edit-bg-btn"
                onClick={() => bgInputRef.current?.click()}
                aria-label="Upload game background from device"
                className="relative overflow-hidden cursor-pointer focus:outline-none transition-transform duration-150 hover:scale-[1.03]"
                style={{
                  width: `${Math.round(artSize * 1.68)}px`,
                  height: `${artSize}px`,
                  borderRadius: '10px',
                  border: `3px solid ${palette.dockRingColor}`,
                  backgroundColor: palette.overlayCardBg,
                }}
              >
                <img
                  src={displayBg}
                  alt="Game Background"
                  referrerPolicy="no-referrer"
                  className="w-full h-full object-cover block"
                />
                <span className="absolute inset-x-0 bottom-0 py-1 px-2 bg-black/75 text-white flex items-center justify-center gap-1 text-[10px] font-ud-semibold">
                  <Wallpaper className="w-3 h-3" />
                  <span>Game Background</span>
                </span>
              </button>
              <input
                ref={bgInputRef}
                type="file"
                accept="image/*"
                onChange={handleBgUpload}
                className="hidden"
              />
            </div>
          </div>

          {/* Game Name (only metadata shown in quick mode) */}
          <div className="flex flex-col items-center gap-2.5 w-full max-w-md">
            {editingTitle ? (
              <form
                onSubmit={(e) => {
                  e.preventDefault();
                  setEditingTitle(false);
                }}
                className="flex items-center gap-2 w-full justify-center"
              >
                <input
                  ref={inputRef}
                  type="text"
                  data-testid="game-edit-title-input"
                  value={draftTitle}
                  onChange={(e) => setDraftTitle(e.target.value)}
                  onBlur={() => {
                    window.getSelection()?.removeAllRanges();
                    setEditingTitle(false);
                  }}
                  maxLength={60}
                  autoFocus
                  className="px-3.5 py-2 rounded-lg text-sm font-ud-semibold text-center focus:outline-none flex-1"
                  style={{
                    backgroundColor: palette.overlayCardBg,
                    color: palette.overlayText,
                    border: `2px solid ${palette.borderPrimary}`,
                  }}
                />
              </form>
            ) : (
              <button
                type="button"
                data-testid="game-edit-open-keyboard"
                onClick={() => {
                  setEditingTitle(true);
                  window.setTimeout(() => inputRef.current?.focus(), 30);
                }}
                className="w-full flex items-center justify-center gap-2.5 px-5 py-2 rounded-lg cursor-pointer transition-colors hover:opacity-85"
                style={{
                  backgroundColor: palette.overlayCardBg,
                  color: palette.overlayText,
                  border: `1px solid ${palette.overlayDivider}`,
                }}
              >
                <span
                  className="font-ud-semibold truncate max-w-sm"
                  style={{ fontSize: `${Math.max(15, Math.round(h * 0.026))}px` }}
                >
                  {draftTitle || game.title}
                </span>
                <Pencil className="w-3.5 h-3.5 shrink-0 opacity-75" />
              </button>
            )}

            {/* Console Type & Release Year — Simple Nintendo-style options shown ONLY from Game Page -> Edit Info */}
            {mode === 'detail' && (
              <div className="w-full flex flex-col gap-2">
                <div
                  data-testid="game-edit-console-row"
                  className="w-full flex items-center justify-between px-4 py-1.5 rounded-lg"
                  style={{
                    backgroundColor: palette.overlayCardBg,
                    border: `1px solid ${palette.overlayDivider}`,
                  }}
                >
                  <span className="text-xs font-ud-medium" style={{ color: palette.overlayMuted }}>
                    Console
                  </span>
                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      data-testid="game-edit-console-prev"
                      onClick={() => stepPlatform(-1)}
                      aria-label="Previous console"
                      className="w-7 h-7 rounded-md flex items-center justify-center cursor-pointer hover:opacity-80"
                      style={{ backgroundColor: palette.overlaySheetBg, color: palette.overlayText }}
                    >
                      <ChevronLeft className="w-4 h-4" />
                    </button>
                    <span
                      data-testid="game-edit-console-value"
                      className="min-w-[144px] text-center text-xs font-ud-bold"
                      style={{ color: palette.overlayText }}
                    >
                      {draftPlatform}
                    </span>
                    <button
                      type="button"
                      data-testid="game-edit-console-next"
                      onClick={() => stepPlatform(1)}
                      aria-label="Next console"
                      className="w-7 h-7 rounded-md flex items-center justify-center cursor-pointer hover:opacity-80"
                      style={{ backgroundColor: palette.overlaySheetBg, color: palette.overlayText }}
                    >
                      <ChevronRight className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                <div
                  data-testid="game-edit-year-row"
                  className="w-full flex items-center justify-between px-4 py-1.5 rounded-lg"
                  style={{
                    backgroundColor: palette.overlayCardBg,
                    border: `1px solid ${palette.overlayDivider}`,
                  }}
                >
                  <span className="text-xs font-ud-medium" style={{ color: palette.overlayMuted }}>
                    Year
                  </span>
                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      data-testid="game-edit-year-prev"
                      onClick={() => stepYear(-1)}
                      aria-label="Previous year"
                      className="w-7 h-7 rounded-md flex items-center justify-center cursor-pointer hover:opacity-80"
                      style={{ backgroundColor: palette.overlaySheetBg, color: palette.overlayText }}
                    >
                      <Minus className="w-3.5 h-3.5" />
                    </button>
                    <input
                      type="text"
                      data-testid="game-edit-year-input"
                      aria-label="Release year"
                      value={draftYear}
                      onChange={(e) => setDraftYear(e.target.value.replace(/[^0-9]/g, '').slice(0, 4))}
                      className="w-[144px] text-center text-xs font-ud-bold bg-transparent focus:outline-none"
                      style={{ color: palette.overlayText }}
                    />
                    <button
                      type="button"
                      data-testid="game-edit-year-next"
                      onClick={() => stepYear(1)}
                      aria-label="Next year"
                      className="w-7 h-7 rounded-md flex items-center justify-center cursor-pointer hover:opacity-80"
                      style={{ backgroundColor: palette.overlaySheetBg, color: palette.overlayText }}
                    >
                      <Plus className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            )}

            {/* Save Button */}
            <button
              type="button"
              data-testid="game-edit-save"
              onClick={handleCommitSave}
              className="px-7 py-1.5 rounded-full text-xs font-ud-bold text-white cursor-pointer hover:opacity-90 active:scale-95 transition-transform"
              style={{ backgroundColor: palette.borderPrimary }}
            >
              Save
            </button>
          </div>
        </div>

        {/* Bottom Footer Row matching UserSelectOverlay */}
        <div style={{ paddingLeft: `${sheetPadX}px`, paddingRight: `${sheetPadX}px` }}>
          <div className="w-full h-px" style={{ backgroundColor: palette.overlayDivider }} />
          <div
            className="flex items-center justify-between"
            style={{ height: `${Math.max(40, Math.round(h * 0.085))}px` }}
          >
            <BottomControllerGlyph size={metrics.helpIconSize} color={palette.overlayText} />

            <div className="flex items-center gap-6">
              <button
                type="button"
                onClick={onClose}
                className="flex items-center gap-2 cursor-pointer hover:opacity-75"
              >
                <SwitchPdfIcon
                  button="B"
                  size={Math.max(20, Math.round(metrics.helpIconSize * 0.65))}
                  fillColor={palette.overlayText}
                  cutoutColor={palette.overlaySheetBg}
                />
                <span
                  className="font-ud-semibold"
                  style={{ fontSize: `${metrics.helpFontSize}px`, color: palette.overlayText }}
                >
                  Close
                </span>
              </button>
              <button
                type="button"
                onClick={handleCommitSave}
                className="flex items-center gap-2 cursor-pointer hover:opacity-75"
              >
                <SwitchPdfIcon
                  button="A"
                  size={Math.max(20, Math.round(metrics.helpIconSize * 0.65))}
                  fillColor={palette.overlayText}
                  cutoutColor={palette.overlaySheetBg}
                />
                <span
                  className="font-ud-semibold"
                  style={{ fontSize: `${metrics.helpFontSize}px`, color: palette.overlayText }}
                >
                  Save
                </span>
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
