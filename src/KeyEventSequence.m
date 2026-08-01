// Plans a complete keyboard event sequence for one configured keystroke.
// Requested modifiers already held by the user are never pressed or released.

#import "KeyEventSequence.h"
#import <IOKit/hidsystem/IOLLEvent.h>

typedef struct {
    CGKeyCode keyCode;
    CGEventFlags genericFlag;
    CGEventFlags flags;
} MGModifier;

size_t MGPlanKeyEventSequence(CGKeyCode keyCode,
                              CGEventFlags requestedFlags,
                              CGEventFlags physicalFlags,
                              MGKeyEventStep steps[10]) {
    static const MGModifier modifiers[] = {
        {56, kCGEventFlagMaskShift, kCGEventFlagMaskShift | NX_DEVICELSHIFTKEYMASK},
        {59, kCGEventFlagMaskControl, kCGEventFlagMaskControl | NX_DEVICELCTLKEYMASK},
        {58, kCGEventFlagMaskAlternate, kCGEventFlagMaskAlternate | NX_DEVICELALTKEYMASK},
        {55, kCGEventFlagMaskCommand, kCGEventFlagMaskCommand | NX_DEVICELCMDKEYMASK},
    };
    size_t count = 0;
    size_t pressed[4];
    size_t pressedCount = 0;
    CGEventFlags activeFlags = 0;

    for (size_t i = 0; i < sizeof(modifiers) / sizeof(modifiers[0]); i++) {
        MGModifier modifier = modifiers[i];
        if (!(requestedFlags & modifier.genericFlag))
            continue;
        if (physicalFlags & modifier.genericFlag) {
            activeFlags |= modifier.flags;
            continue;
        }
        activeFlags |= modifier.flags;
        steps[count++] = (MGKeyEventStep){modifier.keyCode, true, activeFlags};
        pressed[pressedCount++] = i;
    }

    steps[count++] = (MGKeyEventStep){keyCode, true, requestedFlags};
    steps[count++] = (MGKeyEventStep){keyCode, false, requestedFlags};

    while (pressedCount > 0) {
        MGModifier modifier = modifiers[pressed[--pressedCount]];
        activeFlags &= ~modifier.flags;
        steps[count++] = (MGKeyEventStep){modifier.keyCode, false, activeFlags};
    }

    return count;
}
