using System;
using Vintagestory.API.Common;
using Common = Vintagestory.API.Common;

class Program
{
    static int AssertEqual(int expected, int actual, string name)
    {
        if (expected != actual)
        {
            Console.WriteLine($"FAIL: {name} expected={expected} actual={actual}");
            return 1;
        }
        Console.WriteLine($"PASS: {name}");
        return 0;
    }

    static Common.IWorldAccessor MakeWorldWithBlocks(params (int x,int y,int z,string code)[] blocks)
    {
        return new TestWorld(blocks);
    }

    static int Main()
    {
        int fails = 0;

        // table only
        var w1 = MakeWorldWithBlocks((0,0,0,"game:table"));
        var v1 = DiningHallMod.DiningHallSystem.CalculateRoomValue(w1, new Vintagestory.API.Common.BlockPos(0,0,0));
        fails += AssertEqual(10, v1, "table-only");

        // table + gold
        var w2 = MakeWorldWithBlocks((0,0,0,"game:table"),(1,0,0,"game:goldstatue"));
        var v2 = DiningHallMod.DiningHallSystem.CalculateRoomValue(w2, new Vintagestory.API.Common.BlockPos(0,0,0));
        fails += AssertEqual(15, v2, "table-plus-gold");

        // no table
        var w3 = MakeWorldWithBlocks((1,0,0,"game:goldstatue"));
        var v3 = DiningHallMod.DiningHallSystem.CalculateRoomValue(w3, new Vintagestory.API.Common.BlockPos(0,0,0));
        fails += AssertEqual(0, v3, "no-table");

        return fails;
    }
}

// Very small test world that uses the Stubs types
class TestWorld : Vintagestory.API.Common.IWorldAccessor
{
    Vintagestory.API.Common.IBlockAccessor _accessor;
    public TestWorld((int x,int y,int z,string code)[] blocks)
    {
        _accessor = new TestBlockAccessor(blocks);
        Player = new Vintagestory.API.Common.LocalPlayer();
        Logger = new StubsLogger();
    }

    public Vintagestory.API.Common.IBlockAccessor BlockAccessor => _accessor;
    public Vintagestory.API.Common.LocalPlayer Player { get; set; }
    public Vintagestory.API.Common.ILogger Logger { get; set; }
}

class TestBlockAccessor : Vintagestory.API.Common.IBlockAccessor
{
    System.Collections.Generic.Dictionary<string, Vintagestory.API.Common.Block> map = new System.Collections.Generic.Dictionary<string, Vintagestory.API.Common.Block>();
    public TestBlockAccessor((int x,int y,int z,string code)[] blocks)
    {
        foreach (var b in blocks)
        {
            var pos = $"{b.x},{b.y},{b.z}";
            map[pos] = new Vintagestory.API.Common.Block { Code = b.code };
        }
    }
    public Vintagestory.API.Common.Block GetBlock(Vintagestory.API.Common.BlockPos pos)
    {
        var key = $"{pos.X},{pos.Y},{pos.Z}";
        if (map.TryGetValue(key, out var block)) return block;
        return null;
    }
}

class StubsLogger : Vintagestory.API.Common.ILogger
{
    public void Notification(string msg) { }
    public void Warning(string msg) { }
}
