<?php

namespace EduConnect\Protocols;

/**
 * Implementación de una declaración xAPI (Experience API / Tin Can).
 * Estándar ADL para registro de experiencias de aprendizaje.
 *
 * {@see https://github.com/adlnet/xAPI-Spec}
 */
class XapiStatement
{
    private array $statement;

    public function __construct()
    {
        $this->statement = [
            'id' => null,
            'actor' => [],
            'verb' => [],
            'object' => [],
            'result' => [],
            'context' => [],
            'timestamp' => null,
            'stored' => null,
            'authority' => [],
            'version' => '1.0.3',
        ];
    }

    public static function make(): self
    {
        return new self();
    }

    public function withId(string $uuid): self
    {
        $this->statement['id'] = $uuid;
        return $this;
    }

    public function withActor(int $userId, string $name, string $email): self
    {
        $this->statement['actor'] = [
            'objectType' => 'Agent',
            'name' => $name,
            'mbox' => "mailto:{$email}",
            'account' => [
                'homePage' => config('app.url'),
                'name' => (string) $userId,
            ],
        ];
        return $this;
    }

    public function withVerb(string $id, string $display): self
    {
        $this->statement['verb'] = [
            'id' => $id,
            'display' => [
                'en-US' => $display,
                'es-CO' => $this->translateVerb($display),
            ],
        ];
        return $this;
    }

    public function withActivityObject(string $id, string $type, string $name): self
    {
        $this->statement['object'] = [
            'objectType' => 'Activity',
            'id' => $id,
            'definition' => [
                'type' => $type,
                'name' => [
                    'en-US' => $name,
                    'es-CO' => $name,
                ],
            ],
        ];
        return $this;
    }

    public function withResult(?float $score, ?bool $success, ?int $duration, ?string $response): self
    {
        $result = [];
        if ($score !== null) {
            $result['score'] = [
                'raw' => $score,
                'min' => 0,
                'max' => 100,
                'scaled' => $score / 100,
            ];
        }
        if ($success !== null) {
            $result['success'] = $success;
        }
        if ($duration !== null) {
            $result['duration'] = "PT{$duration}S";
        }
        if ($response !== null) {
            $result['response'] = $response;
        }
        $this->statement['result'] = $result;
        return $this;
    }

    public function withContext(string $category, string $learningPathId, bool $isOffline): self
    {
        $this->statement['context'] = [
            'contextActivities' => [
                'category' => [
                    [
                        'id' => config('app.url') . '/xapi/categories/' . $category,
                        'definition' => [
                            'type' => 'http://adlnet.gov/expapi/activities/course',
                            'name' => [
                                'en-US' => $category,
                            ],
                        ],
                    ],
                ],
            ],
            'extensions' => [
                'https://educonnectrural.edu/extensions/learning-path-id' => $learningPathId,
                'https://educonnectrural.edu/extensions/is-offline' => $isOffline,
                'https://educonnectrural.edu/extensions/network-type' => config('educonnect.network_type', 'unknown'),
            ],
        ];
        return $this;
    }

    public function withTimestamp(string $timestamp): self
    {
        $this->statement['timestamp'] = $timestamp;
        $this->statement['stored'] = now()->toIso8601String();
        return $this;
    }

    public function withAuthority(string $name, string $email): self
    {
        $this->statement['authority'] = [
            'objectType' => 'Agent',
            'name' => $name,
            'mbox' => "mailto:{$email}",
        ];
        return $this;
    }

    public function toArray(): array
    {
        return $this->statement;
    }

    public function toJson(): string
    {
        return json_encode($this->statement, JSON_UNESCAPED_UNICODE);
    }

    private function translateVerb(string $verb): string
    {
        $map = [
            'completed' => 'completado',
            'attempted' => 'intentado',
            'passed' => 'aprobado',
            'failed' => 'reprobado',
            'answered' => 'respondido',
            'interacted' => 'interactuado',
            'experienced' => 'experimentado',
            'progressed' => 'progresado',
            'launched' => 'iniciado',
            'terminated' => 'finalizado',
        ];
        return $map[strtolower($verb)] ?? $verb;
    }

    // Verbos xAPI estándar
    public const VERBS = [
        'COMPLETED' => 'http://adlnet.gov/expapi/verbs/completed',
        'ATTEMPTED' => 'http://adlnet.gov/expapi/verbs/attempted',
        'PASSED' => 'http://adlnet.gov/expapi/verbs/passed',
        'FAILED' => 'http://adlnet.gov/expapi/verbs/failed',
        'ANSWERED' => 'http://adlnet.gov/expapi/verbs/answered',
        'INTERACTED' => 'http://adlnet.gov/expapi/verbs/interacted',
        'EXPERIENCED' => 'http://adlnet.gov/expapi/verbs/experienced',
        'PROGRESSED' => 'http://adlnet.gov/expapi/verbs/progressed',
        'LAUNCHED' => 'http://adlnet.gov/expapi/verbs/launched',
        'TERMINATED' => 'http://adlnet.gov/expapi/verbs/terminated',
    ];

    public const ACTIVITY_TYPES = [
        'LESSON' => 'http://adlnet.gov/expapi/activities/lesson',
        'COURSE' => 'http://adlnet.gov/expapi/activities/course',
        'MODULE' => 'http://adlnet.gov/expapi/activities/module',
        'ASSESSMENT' => 'http://adlnet.gov/expapi/activities/assessment',
        'INTERACTION' => 'http://adlnet.gov/expapi/activities/interaction',
        'VIDEO' => 'https://w3id.org/xapi/video/activity-type/video',
        'DOCUMENT' => 'http://activitystrea.ms/schema/1.0/document',
    ];
}
