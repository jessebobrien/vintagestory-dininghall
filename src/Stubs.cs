#if STUBS
using System;

namespace Vintagestory.API.Common
{
    public class ModSystem
    {
        public virtual void StartServerSide(ICoreServerAPI api) { }
        public virtual void StartClientSide(ICoreClientAPI api) { }
    }

    public interface ICoreServerAPI
    {
        ApiEvent Event { get; }
        ILogger Logger { get; }
    }

    public interface ICoreClientAPI
    {
        ApiEvent Event { get; }
        IWorldAccessor World { get; }
        void ShowChatMessage(string msg);
    }

    public interface IServerPlayer { }

    public class ApiEvent
    {
        public Action<IServerPlayer> PlayerJoin;
        public void RegisterCallback(Action<double> cb, int ms) { }
    }

    public interface ILogger
    {
        void Notification(string msg);
        void Warning(string msg);
    }

    public interface IWorldAccessor
    {
        IBlockAccessor BlockAccessor { get; }
        LocalPlayer Player { get; }
        ILogger Logger { get; }
    }

    public interface IBlockAccessor
    {
        Block GetBlock(BlockPos pos);
    }

    public class Block
    {
        public object Code { get; set; }
        public AttributesData Attributes { get; set; }
    }

    public class AttributesData
    {
        public bool HasAttribute(string key) => false;
        public bool GetBool(string key) => false;
    }

    public class BlockPos
    {
        public int X, Y, Z;
        public BlockPos() { }
        public BlockPos(int x, int y, int z) { X = x; Y = y; Z = z; }
        public BlockPos AddCopy(int dx, int dy, int dz) => new BlockPos(X + dx, Y + dy, Z + dz);
        public BlockPos Copy() => new BlockPos(X, Y, Z);
    }

    public class LocalPlayer
    {
        public Entity Entity { get; set; } = new Entity();
    }

    public class Entity
    {
        public Pos Pos { get; set; } = new Pos();
    }

    public class Pos
    {
        public BlockPos AsBlockPos => new BlockPos();
    }

    public class BlockSelection { }
}

namespace Vintagestory.API.Client { }
namespace Vintagestory.API.MathTools { }
namespace Vintagestory.API.Server { }
namespace Vintagestory.API.Config { }
#endif
