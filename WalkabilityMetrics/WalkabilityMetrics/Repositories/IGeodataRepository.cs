using WalkabilityMetrics.Models;

namespace WalkabilityMetrics.Repositories
{
    internal interface IGeodataRepository
    {
        IEnumerable<GridCell> GetWalkableGrid();
        int UpdateWalkabilityScore(IEnumerable<WalkabilityResult> walkabilityResults);
    }
}
