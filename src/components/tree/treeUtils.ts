// Tree stage based on totalHours
export function getTreeStage(totalHours: number): 1 | 2 | 3 | 4 | 5 {
  if (totalHours < 2)  return 1
  if (totalHours < 8)  return 2
  if (totalHours < 25) return 3
  if (totalHours < 60) return 4
  return 5
}

// Fruit stage based on achievementCount (only shown at stage 5)
export function getFruitStage(achievementCount: number): 'none' | 'a' | 'b' | 'c' | 'd' {
  if (achievementCount === 0)  return 'none'
  if (achievementCount === 1)  return 'a'
  if (achievementCount <= 5)   return 'b'
  if (achievementCount <= 15)  return 'c'
  return 'd'
}

export function getTreeImageSrc(stage: 1 | 2 | 3 | 4 | 5): string {
  const map = {
    1: '/assets/tree/tree-1-seed.png',
    2: '/assets/tree/tree-2-sprouting.png',
    3: '/assets/tree/tree-3-sapling.png',
    4: '/assets/tree/tree-4-youthful.png',
    5: '/assets/tree/tree-5-mature.png',
  }
  return map[stage]
}

export function getFruitImageSrc(stage: 'a' | 'b' | 'c' | 'd'): string {
  const map = {
    a: '/assets/tree/fruit-a.png',
    b: '/assets/tree/fruit-b.png',
    c: '/assets/tree/fruit-c.png',
    d: '/assets/tree/fruit-d.png',
  }
  return map[stage]
}
