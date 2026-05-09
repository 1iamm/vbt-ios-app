#!/usr/bin/env bash
# Pre-PR sanity verification for VBTrainer.
#
# Linux container has no Xcode/SDK, so we can't do real type-checking. But
# we can:
#   1. Run `swift -frontend -parse` on every .swift file → catches brace /
#      paren / syntax errors (the EventKitService bug from PR #2).
#   2. Build a project-wide index of declared types and report any
#      PascalCase identifier referenced from code but not declared anywhere
#      and not in the Apple-framework whitelist (the EmptyStateCard bug
#      from PR #4).
#
# Exit non-zero on any finding so CI / pre-push hook can block PR.

set -u

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Find swift-frontend: macOS Xcode → PATH → known Linux container path.
if SWIFT="$(xcrun -f swift-frontend 2>/dev/null)" && [ -x "$SWIFT" ]; then :
elif SWIFT="$(command -v swift-frontend 2>/dev/null)" && [ -n "$SWIFT" ]; then :
elif [ -x /opt/swift-5.10.1-RELEASE-ubuntu22.04/usr/bin/swift-frontend ]; then
    SWIFT=/opt/swift-5.10.1-RELEASE-ubuntu22.04/usr/bin/swift-frontend
else
    echo "error: swift-frontend not found." >&2
    echo "  macOS: install Xcode (xcrun should locate it)" >&2
    echo "  Linux: download from https://www.swift.org/install/linux/" >&2
    exit 2
fi
cd "$ROOT" || exit 1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

echo "==> Pre-PR verify"
echo "    repo: $ROOT"
echo

# Find all sources we care about (skip Tests, .build, openspec)
mapfile -t FILES < <(find Shared VBTrainer "VBTrainerWatch Watch App" \
    -name "*.swift" -not -path "*/Tests/*" 2>/dev/null | sort)

echo "    ${#FILES[@]} .swift files"
echo

FAIL=0

# ──────────────────────────────────────────────────────────────────────────
# Step 1: syntax parse — catches braces/parens/colons errors
# ──────────────────────────────────────────────────────────────────────────
echo -e "${BOLD}[1/2] Syntax parse${NC}"
parse_errors=0
for f in "${FILES[@]}"; do
    out="$($SWIFT -parse "$f" 2>&1)"
    if echo "$out" | grep -q "error:"; then
        echo -e "${RED}  ✗ $f${NC}"
        echo "$out" | grep "error:" | sed 's/^/    /'
        parse_errors=$((parse_errors + 1))
        FAIL=1
    fi
done
if [ "$parse_errors" -eq 0 ]; then
    echo -e "${GREEN}  ✓ all $((${#FILES[@]})) files parse cleanly${NC}"
fi
echo

# ──────────────────────────────────────────────────────────────────────────
# Step 2: cross-file symbol resolution
# ──────────────────────────────────────────────────────────────────────────
echo -e "${BOLD}[2/2] Cross-file symbol resolution${NC}"

DECLARED="$(mktemp)"
WHITELIST="$ROOT/scripts/verify-whitelist.txt"

# 2a. Collect every type/protocol declared anywhere in the project
for f in "${FILES[@]}"; do
    # struct/class/enum/protocol/actor + typealias
    grep -hoE "(struct|class|enum|protocol|actor|typealias)[[:space:]]+[A-Z][A-Za-z0-9_]*" "$f" \
        | awk '{print $2}' >> "$DECLARED"
    # nested generics get cleaned up by awk taking $2 (after keyword)
done
sort -u "$DECLARED" -o "$DECLARED"

# 2b. Whitelist of well-known Apple framework types we expect to use.
#     If you legitimately add a new Apple type, add it here.
mkdir -p "$ROOT/scripts"
if [ ! -f "$WHITELIST" ]; then
    echo "  ! whitelist file missing at $WHITELIST — regenerating with seed defaults." >&2
    cat > "$WHITELIST" <<'EOF'
# Apple framework / standard library types referenced by VBTrainer code.
# One name per line. Lines starting with # are comments.
# Foundation
Date Calendar DateFormatter DateInterval DateComponents UUID URL URLRequest URLSession
TimeInterval Locale Bundle Data NotificationCenter Notification NSError NSObject
NSPredicate NSSortDescriptor NSNumber NSString NSDictionary NSArray NSCoder
NSKeyedArchiver NSKeyedUnarchiver
JSONEncoder JSONDecoder PropertyListEncoder PropertyListDecoder
UserDefaults FileManager DispatchQueue DispatchWorkItem DispatchTime
OperationQueue Operation Process Pipe Timer ProcessInfo Thread
RunLoop AsyncStream Task TaskGroup ContinuousClock SuspendingClock
CharacterSet IndexSet IndexPath OperatingSystemVersion DateFormatter
# Swift stdlib value/collection types
String Int Int8 Int16 Int32 Int64 UInt UInt8 UInt16 UInt32 UInt64
Float Double Bool Character Optional Array Dictionary Set Range ClosedRange
String_StringInterpolation Substring AnyHashable AnyIndex Slice
Iterator IteratorProtocol Sequence Collection BidirectionalCollection
RandomAccessCollection MutableCollection RangeReplaceableCollection
LazySequenceProtocol LazyCollectionProtocol Strideable Stride
NSOrderedSet NSCountedSet NSMutableSet NSMutableArray NSMutableDictionary
StaticString DefaultStringInterpolation
# SwiftData property-wrapper types accidentally caught by the heuristic
Attribute Relationship Transient
# SwiftUI control-flow / collection
ForEach Group AnyView TupleView ConditionalContent EmptyView Text_Storage
ByteCountFormatter NumberFormatter MeasurementFormatter ISO8601DateFormatter
Logger Encoder Decoder Encodable Decodable Codable
Result CheckedThrowingContinuation UnsafeContinuation
Hashable Equatable Comparable Sendable Identifiable
# Combine
AnyCancellable PassthroughSubject CurrentValueSubject AnyPublisher
# SwiftUI core
View Scene App WindowGroup ContentView Group Section Form
Text Image Label Button Toggle Picker Stepper Slider TextField SecureField TextEditor
ProgressView Gauge Link DatePicker ColorPicker
HStack VStack ZStack LazyHStack LazyVStack Grid GridRow LazyHGrid LazyVGrid
GridItem ScrollView ScrollViewReader ScrollViewProxy
NavigationStack NavigationLink NavigationView NavigationPath NavigationSplitView
TabView Sheet ToolbarItem ToolbarItemGroup
Spacer Divider Capsule Circle Rectangle RoundedRectangle Ellipse Path
LinearGradient RadialGradient AngularGradient Gradient Color
Animation Transition AnyTransition Binding State StateObject ObservedObject
EnvironmentObject Environment EnvironmentValues PreferenceKey
ViewBuilder SceneBuilder ToolbarContentBuilder
EdgeInsets Edge Alignment HorizontalAlignment VerticalAlignment
GeometryReader GeometryProxy CGFloat CGSize CGPoint CGRect CGAffineTransform
CGColor CGImage CGContext CGPath
DragGesture TapGesture LongPressGesture MagnificationGesture RotationGesture
GestureState SimultaneousGesture ExclusiveGesture SequenceGesture
ButtonStyle ButtonStyleConfiguration PrimitiveButtonStyle ToggleStyle PickerStyle
ListStyle FormStyle TextFieldStyle ProgressViewStyle DatePickerStyle MenuStyle
LabelStyle TableStyle GroupBoxStyle GaugeStyle DisclosureGroupStyle
StrokeStyle ShapeStyle InsettableShape ContainerRelativeShape AnyShape
SymbolRenderingMode SymbolEffect HierarchicalShapeStyle
AccessibilityAttachmentModifier ViewModifier AnyView EmptyView
RoundedCornerStyle RoundedRectangleCornerStyle FillStyle
ContentUnavailableView ContentMode VerticalEdge HorizontalEdge AnchorPoint
Anchor UnitPoint Axis Visibility ColorScheme PresentationDetent
ToolbarPlacement DismissAction OpenURLAction
TextSelection TextSelectionBehavior PrimaryButtonStyle BorderedButtonStyle
BorderlessButtonStyle PlainButtonStyle DefaultButtonStyle BorderedProminentButtonStyle
DefaultPickerStyle SegmentedPickerStyle WheelPickerStyle MenuPickerStyle
AutomaticPickerStyle PalettePickerStyle InlinePickerStyle NavigationLinkPickerStyle
DefaultDatePickerStyle CompactDatePickerStyle WheelDatePickerStyle GraphicalDatePickerStyle
DefaultListStyle GroupedListStyle InsetGroupedListStyle InsetListStyle
PlainListStyle SidebarListStyle BorderedListStyle CarouselListStyle EllipticalListStyle
GroupBoxStyleConfiguration TabViewStyle DefaultTabViewStyle PageTabViewStyle
VerticalPageTabViewStyle CarouselTabViewStyle TabBarItem
DefaultLabelStyle IconOnlyLabelStyle TitleOnlyLabelStyle TitleAndIconLabelStyle
DefaultTextFieldStyle PlainTextFieldStyle RoundedBorderTextFieldStyle
SquareBorderTextFieldStyle AutomaticTextFieldStyle
DefaultProgressViewStyle CircularProgressViewStyle LinearProgressViewStyle
DefaultGaugeStyle AccessoryCircularGaugeStyle AccessoryCircularCapacityGaugeStyle
AccessoryLinearGaugeStyle AccessoryLinearCapacityGaugeStyle LinearCapacityGaugeStyle
DefaultMenuStyle BorderlessButtonMenuStyle ButtonMenuStyle
DefaultDisclosureGroupStyle AutomaticDisclosureGroupStyle
DisclosureIndicatorMenuStyle Menu MenuOrder MenuStyleConfiguration
SearchSuggestionsPlacement SearchScopeActivation
GroupedFormStyle ColumnsFormStyle AutomaticFormStyle
DefaultToggleStyle SwitchToggleStyle CheckboxToggleStyle ButtonToggleStyle
PaletteSelectionEffect ContentTransition ContentTransitionAttachment
KeyEquivalent KeyboardShortcut EventModifiers
FocusState FocusedBinding FocusedValue FocusedValues FocusedObject
MaterialThicknessVariant Material MaterialKind MaterialFinish
DocumentGroup DocumentGroupLaunchScene DocumentLaunchScene FileDocument ReferenceFileDocument
WindowResizability WindowToolbarStyle WindowStyle WindowTabbingMode
DismissBehavior PresentationBackgroundInteraction PresentationContentInteraction
PresentationAdaptation OnEnterValue OnExitValue
RedactionReasons CommandsBuilder Commands CommandMenu CommandGroup
TextRenderer Text_LineLimit
# UIKit
UIApplication UIViewController UINavigationController UITabBarController
UIView UILabel UIButton UIImageView UIImage UIColor UIFont UIScreen
UIDevice UIWindow UIWindowScene UISceneSession UIPasteboard UIAccessibility
UISwipeGestureRecognizer UITapGestureRecognizer UILongPressGestureRecognizer
UIEdgeInsets UIRectCorner UIInterfaceOrientation UIInterfaceOrientationMask
UIStackView UIScrollView UICollectionView UITableView UITextField UITextView
UISwitch UISlider UIDatePicker UISegmentedControl UIActivityIndicatorView
UIRefreshControl UISearchBar UISearchController UIPageControl
UINotificationFeedbackGenerator UISelectionFeedbackGenerator UIImpactFeedbackGenerator
UIFeedbackGenerator UIReferenceLibraryViewController
UIDocumentPickerViewController UIActivityViewController
UIAlertController UIAlertAction UIBarButtonItem UIToolbar UISearchTextField
UIResponder UITraitCollection UITraitEnvironment
UIBezierPath UIVisualEffect UIBlurEffect UIVibrancyEffect UIVisualEffectView
UIPanGestureRecognizer UIRotationGestureRecognizer UIPinchGestureRecognizer
# WatchKit
WKExtension WKApplicationDelegate WKExtensionDelegate WKHostingController
WKInterfaceController WKInterfaceObject WKInterfaceLabel WKInterfaceButton
WKBackgroundTask WKApplicationRefreshBackgroundTask WKExtendedRuntimeSession
WKExtendedRuntimeSessionDelegate
WKWatchConnectivityRefreshBackgroundTask
WKHapticType WKAlertActionStyle
# WatchConnectivity
WCSession WCSessionDelegate WCSessionActivationState
# CoreMotion
CMMotionManager CMDeviceMotion CMAccelerometerData CMAcceleration CMRotationRate
CMAttitude CMQuaternion CMSensorRecorder CMPedometer CMPedometerData
# HealthKit
HKHealthStore HKWorkoutSession HKWorkoutBuilder HKLiveWorkoutBuilder
HKLiveWorkoutDataSource HKWorkoutConfiguration HKQuantityType HKObjectType
HKSampleType HKQuantitySample HKCategorySample HKSample HKWorkout HKQuery
HKSampleQuery HKAnchoredObjectQuery HKObserverQuery HKStatisticsQuery
HKStatisticsCollectionQuery HKQuantityTypeIdentifier HKCategoryTypeIdentifier
HKCategoryValueSleepAnalysis HKWorkoutActivityType HKWorkoutSessionLocationType
HKQueryAnchor HKObjectQueryNoLimit HKAuthorizationStatus
HKUnit HKQuantity HKBiologicalSex HKBloodType HKFitzpatrickSkinType
HKErrorCode HKAuthorizationRequestStatus HKObject
# EventKit
EKEventStore EKEvent EKCalendar EKAlarm EKRecurrenceRule EKReminder
EKEntityType EKAuthorizationStatus EKSource EKSourceType EKSpan
EKParticipant EKEventAvailability EKWeekday EKRecurrenceFrequency
EKRecurrenceEnd EKRecurrenceDayOfWeek EKStructuredLocation EKCalendarItem
# SwiftData
ModelContainer ModelContext ModelConfiguration Schema PersistentModel Model
FetchDescriptor FetchResultsCollection Query Predicate SortDescriptor
PersistentIdentifier ModelMigrationPlan SchemaMigrationPlan
# Charts
Chart ChartContent ChartProxy ChartXAxis ChartYAxis ChartXScale ChartYScale
LineMark PointMark BarMark RectangleMark RuleMark AreaMark RangeAreaMark
SectorMark ChartPlotContent AxisMarks AxisGridLine AxisTick AxisValueLabel
AxisValue ChartContentBuilder ChartCategoryAxis
# simd
SIMD2 SIMD3 SIMD4 simd_quatd simd_quatf simd_double3 simd_double4 simd_float3
# misc UIKit/AVFoundation/etc.
AVAudioSession AVAudioPlayer AVAudioRecorder AVPlayer AVPlayerItem
CLLocationManager CLLocation
EOF
fi

# Read whitelist into associative array
declare -A WL
while IFS= read -r line; do
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    for tok in $line; do WL["$tok"]=1; done
done < "$WHITELIST"

# Read declared types into associative array
declare -A DECL
while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    DECL["$line"]=1
done < "$DECLARED"

# 2c. For each file, find PascalCase identifiers used in callsite-like
#     positions (Word(...) at start of expression or after . or = or :).
#     Skip when in comment or string.
unresolved_count=0
unresolved_seen=""

for f in "${FILES[@]}"; do
    # crude tokenizer: pull Word( occurrences after we strip // comments and "..." strings
    # Use sed to drop // tail comments and replace strings with empty.
    cleaned="$(sed -E 's://.*$::' "$f" | sed -E 's/"[^"]*"//g')"
    # PascalCase ident followed by `(`, NOT preceded by `.` (method) or `@` (attribute)
    used="$(echo "$cleaned" | grep -oP '(?<![.\w@])[A-Z][A-Za-z0-9_]+\(' | sed 's/($//' | sort -u)"
    for sym in $used; do
        if [ -z "${DECL[$sym]+x}" ] && [ -z "${WL[$sym]+x}" ]; then
            # also skip if it's a method on Self.method (unlikely PascalCase)
            if echo "$unresolved_seen" | grep -qw "$sym"; then continue; fi
            unresolved_seen="$unresolved_seen $sym"
            echo -e "${RED}  ✗ $sym${NC} — referenced in $f"
            unresolved_count=$((unresolved_count + 1))
            FAIL=1
        fi
    done
done

if [ "$unresolved_count" -eq 0 ]; then
    echo -e "${GREEN}  ✓ all referenced types declared or whitelisted${NC}"
fi
echo

rm -f "$DECLARED"

# ──────────────────────────────────────────────────────────────────────────
# Final
# ──────────────────────────────────────────────────────────────────────────
if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}${BOLD}✓ verify passed${NC}"
    exit 0
else
    echo -e "${RED}${BOLD}✗ verify failed — fix the issues above before opening a PR${NC}"
    echo
    echo "Hints:"
    echo "  - Brace/syntax errors → fix the indicated line"
    echo "  - Unresolved type → either declare it or add to scripts/verify-whitelist.txt"
    exit 1
fi
