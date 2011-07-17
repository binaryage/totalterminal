typedef enum {
    vHistorical=0,// this position is important for comparing, we try to treat all prior to 10.6.8 as historical
    v273_1 = 100, // 10.6.8
    v294,         // 10.7 (Lion GM)
    vUnknown,     // this position is important for comparing, we assume unknown are future Terminal versions
    vMaxSupportedTerminalVersion
} TSupportedTerminalVersions;

#define FIRST_LION_VERSION v294

extern TSupportedTerminalVersions initializeTerminalVersion();
extern TSupportedTerminalVersions terminalVersion();