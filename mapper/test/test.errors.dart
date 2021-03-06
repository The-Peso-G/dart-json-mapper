part of json_mapper.test;

class UnAnnotated {}

enum Sex { Male, Female }
const sexTypeValues = ['__female', '__male'];

@jsonSerializable
@Json(allowCircularReferences: 1)
class MyCar extends Car {
  MyCar(model, color) : super(model, color);
}

@jsonSerializable
class Device {}

@jsonSerializable
class UserSettings {
  List<Device> devices;
  UserSettings(this.devices);
}

@jsonSerializable
class UnAnnotatedEnumField {
  Sex sex = Sex.Female;
}

@jsonSerializable
class WrongAnnotatedEnumField {
  @JsonProperty(enumValues: sexTypeValues)
  Sex sex = Sex.Female;
}

typedef ErrorGeneratorFunction = dynamic Function();
dynamic catchError(ErrorGeneratorFunction errorGenerator) {
  var targetError;
  try {
    errorGenerator();
  } catch (error) {
    targetError = error;
  }
  return targetError;
}

void testErrorHandling() {
  group('[Verify error handling]', () {
    test('Circular reference detection during serialization', () {
      final car = Car('VW', Color.Blue);
      car.replacement = car;
      expect(catchError(() => JsonMapper.serialize(car)),
          TypeMatcher<CircularReferenceError>());
    });

    test('[Suppress] Circular reference detection during serialization', () {
      final car = MyCar('VW', Color.Blue);
      car.replacement = car;
      expect(catchError(() => JsonMapper.serialize(car, compactOptions)), null);
    });

    test('Allow using same object same level during serialization', () {
      final device = Device();
      final us = UserSettings([device, device]);

      expect(catchError(() => JsonMapper.serialize(us, compactOptions)), null);
    });

    test('Missing annotation on class', () {
      expect(catchError(() => JsonMapper.serialize(UnAnnotated())),
          TypeMatcher<MissingAnnotationOnTypeError>());
    });

    test('Missing annotation on Enum field', () {
      final json = '''{"sex":"Sex.Female"}''';
      // Deserialize unannotated enum should NOT be fine
      expect(
          catchError(() => JsonMapper.deserialize<UnAnnotatedEnumField>(json)),
          TypeMatcher<MissingEnumValuesError>());
    });

    test('Wrong enumValues in annotation on Enum field', () {
      final json = '{"sex":"Sex.Female"}';
      expect(catchError(() {
        JsonMapper.deserialize<WrongAnnotatedEnumField>(json);
      }), TypeMatcher<InvalidEnumValueError>());
    });

    test('Missing target type for deserialization', () {
      expect(catchError(() => JsonMapper.deserialize('{}')),
          TypeMatcher<MissingTypeForDeserializationError>());
    });
  });
}
