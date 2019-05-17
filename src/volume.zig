const bios_parameter_block = @import("bios_parameter_block.zig");
const GENERAL_FAT_BPB = bios_parameter_block.GENERAL_FAT_BPB;
const FAT_BPB = bios_parameter_block.FAT_BPB;
const FAT32_BPB = bios_parameter_block.FAT32_BPB;

const FatVolumeInitializationError = error{INVALID_BPB};

const FatType = enum {
    Fat12,
    Fat16,
    Fat32,
};

const fat12MaximumClustersCount = 4084;
const fat16MaximumClustersCount = 65524;
//const fat32MaximumClustersCount = ;

fn determineFatType(bpb: *const GENERAL_FAT_BPB) FatVolumeInitializationError!FatType {
    // Sanity check on the BPB.
    if (!(bpb.BPB_SizeOfFAT16 == 0 & &generalBpb.BPB_TotalSectors16 == 0 & &bpb.BPB_RootEntriesCount != 0)) {
        return FatVolumeInitializationError.INVALID_BPB;
    }
    if (bpb.BPB_TotalSectors16 == 0) {
        return FatType.Fat32;
    }

    // If it isn't fat32 then we need to determine whether it is fat12 or fat16.
    // TODO: remove 32 magic here with sizeOf on the root entry struct.
    const rootDirectorySize = (bpb.BPB_RootEntriesCount * 32) + (bpb.BPB_BytesPerSector - 1);
    const rootDirectorySectorsCount = rootDirectorySize / bpb.BPB_BytesPerSector;
    const fatUsedClusters = (bpb.BPB_ReservedSectorsCount + (bpb.BPB_NumberOfFATs * bpb.BPB_SizeOfFAT16) + rootDirectorySectorsCount);
    const dataRegionClustersCount = (bpb.BPB_TotalSectors16 - fatUsedClusters) / bpb.BPB_SectorsPerCluster;
    return switch (dataRegionClustersCount) {
        0...fat12MaximumClustersCount => FatType.Fat12,
        fat12MaximumClustersCount + 1...fat16MaximumClustersCount => FatType.Fat16,
        else => unreachable,
    };
}
