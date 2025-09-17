using System;
using Vintagestory.API.Common;
using Vintagestory.API.Server;
using Vintagestory.API.MathTools;
using Vintagestory.API.Client;
using Vintagestory.API.Config;

namespace DiningHallMod
{
    public class DiningHallSystem : ModSystem
    {
        ICoreServerAPI sapi;
        private bool wasInHall = false;

        public override void StartServerSide(ICoreServerAPI api)
        {
            sapi = api;
            api.Event.PlayerJoin += OnPlayerJoin;

            api.Logger.Notification("DiningHall mod loaded (server)");
        }

        private void OnPlayerJoin(IServerPlayer byPlayer)
        {
            // Server-side setup could go here if needed later
        }

        /// <summary>
        /// Calculate a simple room 'value' around a position.
        /// Heuristic: search within a box (7x4x7) for a table (adds base value)
        /// and other blocks whose code contains "gold" or "engraving" add extra value.
        /// </summary>
        public static int CalculateRoomValue(IWorldAccessor world, BlockPos pos)
        {
            int value = 0;

            int rangeX = 3;
            int rangeY = 2;
            int rangeZ = 3;

            for (int dx = -rangeX; dx <= rangeX; dx++)
            {
                for (int dy = -1; dy <= rangeY; dy++)
                {
                    for (int dz = -rangeZ; dz <= rangeZ; dz++)
                    {
                        BlockPos p = pos.AddCopy(dx, dy, dz);
                        Block block = world.BlockAccessor.GetBlock(p);
                        if (block == null) continue;

                        string code = block.Code?.ToString() ?? "";

                        // If we find a table-like block, give a base value
                        if (code.IndexOf("table", StringComparison.OrdinalIgnoreCase) >= 0)
                        {
                            value += 10;
                        }

                        // Furnishings with gold/engraving increase value
                        if (code.IndexOf("gold", StringComparison.OrdinalIgnoreCase) >= 0
                            || code.IndexOf("engraving", StringComparison.OrdinalIgnoreCase) >= 0)
                        {
                            value += 5;
                        }

                        // (Deliberately avoid using Attributes helpers here to remain compatible with runtime API types.)
                    }
                }
            }

            return value;
        }

        // Client-side: show debug message when player is in a room that contains a table (room value > 0)
        public override void StartClientSide(ICoreClientAPI api)
        {
            base.StartClientSide(api);
            api.Event.RegisterCallback(dt => ClientTick(api), 1000);
        }

        private void ClientTick(ICoreClientAPI capi)
        {
            try
            {
                BlockPos pos = capi.World.Player.Entity.Pos.AsBlockPos;
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