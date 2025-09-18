using System;
#if STUBS
using Common = Vintagestory.API.Common;
using Server = Vintagestory.API.Common;
using Math = Vintagestory.API.Common;
using Client = Vintagestory.API.Common;
#else
using Common = Vintagestory.API.Common;
using Server = Vintagestory.API.Server;
using Math = Vintagestory.API.MathTools;
using Client = Vintagestory.API.Client;
#endif
using Vintagestory.API.Config;

namespace DiningHallMod
{
    public class ModConfig
    {
        public int TableBaseValue { get; set; } = 10;
        public int FurnishingWeight { get; set; } = 5;
        public int RangeX { get; set; } = 3;
        public int RangeY { get; set; } = 2;
        public int RangeZ { get; set; } = 3;
    }

    public class DiningHallSystem : Common.ModSystem
    {
        Server.ICoreServerAPI sapi;
        private bool wasInHall = false;
        private static ModConfig config = new ModConfig();

        static DiningHallSystem()
        {
            try
            {
                var cfgPath = System.IO.Path.Combine(System.IO.Directory.GetCurrentDirectory(), "modconfig.json");
                if (System.IO.File.Exists(cfgPath))
                {
                    var txt = System.IO.File.ReadAllText(cfgPath);
                    // Lightweight parser: extract integer properties by name. This avoids needing
                    // System.Web.Script.Serialization or external JSON libraries in test builds.
                    int ParseInt(string key, int fallback)
                    {
                        try
                        {
                            var pattern = "\"" + key + "\"\\s*:\\s*(\\d+)";
                            var rx = new System.Text.RegularExpressions.Regex(pattern, System.Text.RegularExpressions.RegexOptions.IgnoreCase);
                            var m = rx.Match(txt);
                            if (m.Success && int.TryParse(m.Groups[1].Value, out var v)) return v;
                        }
                        catch { }
                        return fallback;
                    }

                    config.TableBaseValue = ParseInt(nameof(ModConfig.TableBaseValue), config.TableBaseValue);
                    config.FurnishingWeight = ParseInt(nameof(ModConfig.FurnishingWeight), config.FurnishingWeight);
                    config.RangeX = ParseInt(nameof(ModConfig.RangeX), config.RangeX);
                    config.RangeY = ParseInt(nameof(ModConfig.RangeY), config.RangeY);
                    config.RangeZ = ParseInt(nameof(ModConfig.RangeZ), config.RangeZ);
                }
            }
            catch { /* fall back to defaults */ }
        }

        public override void StartServerSide(Server.ICoreServerAPI api)
        {
            sapi = api;
            api.Event.PlayerJoin += OnPlayerJoin;

            api.Logger.Notification("DiningHall mod loaded (server)");
        }

        // ...existing code...

        private void OnPlayerJoin(Server.IServerPlayer byPlayer)
        {
            // Server-side setup could go here if needed later
        }

        /// <summary>
        /// Calculate a simple room 'value' around a position.
        /// Heuristic: search within a box (7x4x7) for a table (adds base value)
        /// and other blocks whose code contains "gold" or "engraving" add extra value.
        /// </summary>
        public static int CalculateRoomValue(Common.IWorldAccessor world, Math.BlockPos pos)
        {
            int rangeX = config.RangeX;
            int rangeY = config.RangeY;
            int rangeZ = config.RangeZ;

            int tablesFound = 0;
            int furnishingCount = 0;

            // First pass: collect counts
            for (int dx = -rangeX; dx <= rangeX; dx++)
            {
                for (int dy = -1; dy <= rangeY; dy++)
                {
                    for (int dz = -rangeZ; dz <= rangeZ; dz++)
                    {
                        Math.BlockPos p = pos.AddCopy(dx, dy, dz);
                        Common.Block block = world.BlockAccessor.GetBlock(p);
                        if (block == null) continue;

                        string code = block.Code?.ToString() ?? "";

                        if (code.IndexOf("table", StringComparison.OrdinalIgnoreCase) >= 0)
                        {
                            tablesFound++;
                        }

                        if (code.IndexOf("gold", StringComparison.OrdinalIgnoreCase) >= 0
                            || code.IndexOf("engraving", StringComparison.OrdinalIgnoreCase) >= 0)
                        {
                            furnishingCount++;
                        }
                    }
                }
            }

            if (tablesFound == 0) return 0;

            int value = tablesFound * config.TableBaseValue + furnishingCount * config.FurnishingWeight;
            return value;
        }

        // Client-side: show debug message when player is in a room that contains a table (room value > 0)
        public override void StartClientSide(Client.ICoreClientAPI api)
        {
            base.StartClientSide(api);
            api.Event.RegisterCallback(dt => ClientTick(api), 1000);
        }

        private void ClientTick(Client.ICoreClientAPI capi)
        {
            try
            {
                Math.BlockPos pos = capi.World.Player.Entity.Pos.AsBlockPos;
                int value = CalculateRoomValue(capi.World, pos);

                bool inHall = value > 0;

                if (inHall && !wasInHall)
                {
                    capi.ShowChatMessage($"[DiningHall] Entered dining area — value: {value}");
                }
                else if (!inHall && wasInHall)
                {
                    capi.ShowChatMessage("[DiningHall] Left dining area");
                }

                // If still inside, show occasional debug info (every tick could be noisy)
                if (inHall && wasInHall)
                {
                    // small, less frequent debug message
                    capi.ShowChatMessage($"[DiningHall DEBUG] Room value: {value}");
                }

                wasInHall = inHall;
            }
            catch (Exception ex)
            {
                capi.World.Logger.Warning("DiningHall client tick error: " + ex.Message);
            }

            // re-register
            capi.Event.RegisterCallback(dt => ClientTick(capi), 2000);
        }
    }
}